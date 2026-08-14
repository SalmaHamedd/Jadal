import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Local key/value store, backed by a single JSON file.
///
/// ## Why this is serialized and cached
///
/// Every write used to be an *unsynchronised* read-modify-write of the whole
/// file: read the map, set one key, write the map back — while
/// `writeAsString` truncates the file before writing it. With concurrent
/// callers that produced two ways to silently destroy the session:
///
///  1. **Lost update.** Two writers both read the old map; the second one to
///     finish writes its copy back, discarding the first's key. When the key
///     that lost was `AUTH_TOKEN`, the user stayed "logged in" in the UI while
///     every request 401'd.
///  2. **Torn read.** A reader hitting the file between truncate and write got
///     empty/!JSON content, silently fell back to `{}`, and then persisted
///     that `{}` plus its own key — **wiping the token and everything else**.
///
/// Both were always possible, but became routine once login and profile loads
/// started writing ~20 keys (identity + contact details) instead of a handful,
/// some of them fire-and-forget from a cubit.
///
/// Three things make it safe now:
///  * **One in-memory map is the source of truth**, loaded once. Reads never
///    touch the disk, so a read can't observe a half-written file.
///  * **Every mutation runs through [_lock]**, a serial queue, so read-modify-
///    write sequences can't interleave.
///  * **Writes are atomic**: a temp file is written and flushed, then renamed
///    over the real one. A crash mid-write leaves the previous file intact
///    rather than a truncated one.
///
/// Prefer [setValues] over several [setValue] calls: one flush instead of N.
class PreferencesDatabase {
  static final PreferencesDatabase _instance = PreferencesDatabase._internal();
  factory PreferencesDatabase() => _instance;

  PreferencesDatabase._internal();

  File? _storageFile;

  /// The authoritative map once [_ensureLoaded] has run. On web this is the
  /// only storage.
  final Map<String, String> _memory = {};
  bool _loaded = false;

  /// Serial queue. Each operation chains onto the previous one's completion,
  /// so no two read-modify-write sequences overlap.
  Future<void> _lock = Future.value();

  final String _secretKey = 'v3ryS3cur3AndR4nd0mAESKey00012345';

  /// Runs [action] with exclusive access to [_memory] and the file.
  Future<T> _synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _lock = _lock.then((_) async {
      try {
        completer.complete(await action());
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  Future<File> get _localFile async {
    if (_storageFile != null) return _storageFile!;
    final dir = await getApplicationDocumentsDirectory();
    final file = File(join(dir.path, 'app_preferences.json'));
    if (!(await file.exists())) {
      await file.writeAsString(json.encode({}), flush: true);
    }
    _storageFile = file;
    return file;
  }

  /// Loads the file into [_memory] exactly once. **Must be called inside the
  /// lock.** A parse failure keeps whatever is already in memory rather than
  /// resetting to empty — a corrupt read must never be able to erase the
  /// session.
  Future<void> _ensureLoaded() async {
    if (_loaded || kIsWeb) {
      _loaded = true;
      return;
    }
    try {
      final content = await (await _localFile).readAsString();
      if (content.isNotEmpty) {
        final decoded = json.decode(content);
        if (decoded is Map<String, dynamic>) {
          _memory
            ..clear()
            ..addAll(decoded.map((k, v) => MapEntry(k, v.toString())));
        }
      }
    } catch (_) {
      // Unreadable/corrupt: keep the in-memory map as-is.
    }
    _loaded = true;
  }

  /// Atomically persists [_memory]. **Must be called inside the lock.**
  Future<void> _flush() async {
    if (kIsWeb) return;
    final file = await _localFile;
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(json.encode(_memory), flush: true);
    // rename() is atomic on the same filesystem, so a reader either sees the
    // whole old file or the whole new one — never a truncated one.
    await tmp.rename(file.path);
  }

  Future<void> setValue(String key, dynamic value) =>
      setValues({key: value});

  /// Writes several keys in ONE flush. A null value removes the key, which is
  /// what callers caching optional fields (contact details, avatar) want.
  Future<void> setValues(Map<String, dynamic> entries) => _synchronized(() async {
        await _ensureLoaded();
        var changed = false;
        entries.forEach((key, value) {
          if (value == null) {
            changed |= _memory.remove(key) != null;
          } else {
            final encoded = json.encode(value);
            if (_memory[key] != encoded) {
              _memory[key] = encoded;
              changed = true;
            }
          }
        });
        if (changed) await _flush();
      });

  Future<T?> getValue<T>(String key) => _synchronized(() async {
        await _ensureLoaded();
        final val = _memory[key];
        if (val == null) return null;
        try {
          return json.decode(val) as T;
        } catch (_) {
          return null;
        }
      });

  Future<void> removeValue(String key) => removeValues([key]);

  Future<void> removeValues(List<String> keys) => _synchronized(() async {
        await _ensureLoaded();
        var changed = false;
        for (final key in keys) {
          changed |= _memory.remove(key) != null;
        }
        if (changed) await _flush();
      });

  /// Builds a valid AES-256 key (exactly 32 bytes) from [_secretKey].
  ///
  /// `encrypt.Key.fromUtf8` does no length validation, so a secret that isn't
  /// 16/24/32 bytes long makes AES throw `ArgumentError` at encrypt time. We
  /// pad/truncate to 32 bytes here so an off-length constant can't break it.
  encrypt.Key _aesKey() {
    final raw = utf8.encode(_secretKey);
    final bytes = Uint8List(32);
    bytes.setRange(0, raw.length < 32 ? raw.length : 32, raw);
    return encrypt.Key(bytes);
  }

  String _encrypt(String plainText) {
    final key = _aesKey();
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.encrypt(plainText, iv: iv).base64;
  }

  String _decrypt(String base64Text) {
    final key = _aesKey();
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt64(base64Text, iv: iv);
  }

  Future<void> setEncryptedValue(String key, dynamic value) async {
    final encoded = json.encode(value);
    final encrypted = _encrypt(encoded);
    await setValue(key, encrypted);
  }

  Future<T?> getEncryptedValue<T>(String key) async {
    final encrypted = await getValue<String>(key);
    if (encrypted == null) return null;
    try {
      final decrypted = _decrypt(encrypted);
      return json.decode(decrypted) as T;
    } catch (_) {
      return null;
    }
  }

  Future<void> setToken(String token) => setValue('AUTH_TOKEN', token);

  Future<String?> getToken() => getValue<String>('AUTH_TOKEN');

  Future<void> printPreferencesTable() async {
    try {
      final data = await _synchronized(() async {
        await _ensureLoaded();
        return Map<String, String>.from(_memory);
      });
      if (data.isNotEmpty) {
        debugPrint('Columns in "preferences" table: key, value');
      }
      debugPrint('\nContents of "preferences" table:');
      data.forEach((key, value) => debugPrint('{key: $key, value: $value}'));
      if (data.isEmpty) {
        debugPrint('The "preferences" table is empty.');
      }
    } catch (e) {
      debugPrint('Error reading "preferences" table: $e');
    }
  }

  Future<void> clearAll() => _synchronized(() async {
        await _ensureLoaded();
        _memory.clear();
        await _flush();
      });
}
