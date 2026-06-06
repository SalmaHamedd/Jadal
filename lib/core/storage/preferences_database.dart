import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class PreferencesDatabase {
  static final PreferencesDatabase _instance = PreferencesDatabase._internal();
  factory PreferencesDatabase() => _instance;

  PreferencesDatabase._internal();

  Database? _db;

  // Web fallback: in-memory only, no persistence across reloads.
  final Map<String, String> _memory = {};

  final String _secretKey = 'v3ryS3cur3AndR4nd0mAESKey00012345';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'app_preferences.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE preferences (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  Future<void> setValue(String key, dynamic value) async {
    final stringValue = json.encode(value);
    if (kIsWeb) {
      _memory[key] = stringValue;
      return;
    }
    final db = await database;
    await db.insert(
      'preferences',
      {'key': key, 'value': stringValue},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    final db = await database;
    final result = await db.query(
      'preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isNotEmpty) {
      final val = result.first['value'] as String;
      try {
        final decoded = json.decode(val);
        return decoded as T;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> removeValue(String key) async {
    if (kIsWeb) {
      _memory.remove(key);
      return;
    }
    final db = await database;
    await db.delete(
      'preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
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
      final List<Map<String, dynamic>> rows = await _db!.query('preferences');

      if (rows.isNotEmpty) {
        print('Columns in "preferences" table: ${rows.first.keys.join(', ')}');
      }

      print('\nContents of "preferences" table:');
      for (final row in rows) {
        print(row);
      }

      if (rows.isEmpty) {
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
