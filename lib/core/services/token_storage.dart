import '../storage/preferences_database.dart';

/// Thin wrapper around [PreferencesDatabase] so existing callers keep using the
/// same static API. Tokens are stored encrypted in the local sqflite-backed
/// preferences database (shared_preferences is no longer used).
class TokenStorage {
  static final PreferencesDatabase _prefs = PreferencesDatabase();

  static const String _tokenKey = 'AUTH_TOKEN';

  static Future<void> saveToken(String token) => _prefs.setToken(token);

  static Future<String?> getToken() => _prefs.getToken();

  static Future<void> deleteToken() => _prefs.removeValue(_tokenKey);
}
