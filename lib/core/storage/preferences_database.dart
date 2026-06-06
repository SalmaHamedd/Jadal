import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PreferencesDatabase {
  static final PreferencesDatabase _instance = PreferencesDatabase._internal();
  factory PreferencesDatabase() => _instance;

  PreferencesDatabase._internal();

  File? _storageFile;
  final Map<String, String> _memory = {};
  final String _secretKey = 'v3ryS3cur3AndR4nd0mAESKey00012345';

  Future<File> get _localFile async {
    if (_storageFile != null) return _storageFile!;

    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'app_preferences.json');
    final file = File(path);

    if (!(await file.exists())) {
      await file.writeAsString(json.encode({}), flush: true);
    }

    _storageFile = file;
    return file;
  }

  Future<Map<String, String>> _readStorage() async {
    final file = await _localFile;

    try {
      final content = await file.readAsString();
      if (content.isEmpty) return {};

      final decoded = json.decode(content);
      if (decoded is Map<String, dynamic>) {
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (_) {}

    return {};
  }

  Future<void> _writeStorage(Map<String, String> data) async {
    final file = await _localFile;
    await file.writeAsString(json.encode(data), flush: true);
  }

  Future<void> setValue(String key, dynamic value) async {
    final stringValue = json.encode(value);
    if (kIsWeb) {
      _memory[key] = stringValue;
      return;
    }

    final data = await _readStorage();
    data[key] = stringValue;
    await _writeStorage(data);
  }

  Future<T?> getValue<T>(String key) async {
    if (kIsWeb) {
      final val = _memory[key];
      if (val == null) return null;
      try {
        return json.decode(val) as T;
      } catch (_) {
        return null;
      }
    }

    final data = await _readStorage();
    final val = data[key];
    if (val == null) return null;

    try {
      return json.decode(val) as T;
    } catch (_) {
      return null;
    }
  }

  Future<void> removeValue(String key) async {
    if (kIsWeb) {
      _memory.remove(key);
      return;
    }

    final data = await _readStorage();
    if (!data.containsKey(key)) return;
    data.remove(key);
    await _writeStorage(data);
  }

  String _encrypt(String plainText) {
    final key = encrypt.Key.fromUtf8(_secretKey);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.encrypt(plainText, iv: iv).base64;
  }

  String _decrypt(String base64Text) {
    final key = encrypt.Key.fromUtf8(_secretKey);
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

  Future<void> setToken(String token) async {
    await setEncryptedValue('AUTH_TOKEN', token);
  }

  Future<String?> getToken() async {
    return await getEncryptedValue<String>('AUTH_TOKEN');
  }

  Future<void> printPreferencesTable() async {
    try {
      if (kIsWeb) {
        if (_memory.isNotEmpty) {
          print('Columns in "preferences" table: key, value');
        }
        print('\nContents of "preferences" table:');
        _memory.forEach((k, v) => print({'key': k, 'value': v}));
        if (_memory.isEmpty) {
          print('The "preferences" table is empty.');
        }
        return;
      }

      final data = await _readStorage();
      if (data.isNotEmpty) {
        print('Columns in "preferences" table: key, value');
      }

      print('\nContents of "preferences" table:');
      data.forEach((key, value) => print({'key': key, 'value': value}));

      if (data.isEmpty) {
        print('The "preferences" table is empty.');
      }
    } catch (e) {
      print('Error reading "preferences" table: $e');
    }
  }
}

Future<String> getDocumentsPath() async {
  if (kIsWeb) {
    return '/web_documents';
  }

  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}
