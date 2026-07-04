import '../storage/preferences_database.dart';

/// Thin wrapper around [PreferencesDatabase] so existing callers keep using the
/// same static API. Tokens are stored encrypted in the local sqflite-backed
/// preferences database (shared_preferences is no longer used).
class TokenStorage {
  static final PreferencesDatabase _prefs = PreferencesDatabase();

  static const String _tokenKey = 'AUTH_TOKEN';
  static const String _roleKey = 'AUTH_ROLE';

  static Future<void> saveToken(String token) => _prefs.setToken(token);

  static Future<String?> getToken() => _prefs.getToken();

  static Future<void> deleteToken() => _prefs.removeValue(_tokenKey);

  /// The logged-in user's global account role ('debater' | 'judge' | 'trainer'),
  /// cached at login so role-gated UI (e.g. the registration options) can read it
  /// without a round-trip.
  static Future<void> saveRole(String role) => _prefs.setValue(_roleKey, role);

  static Future<String?> getRole() => _prefs.getValue<String>(_roleKey);

  static Future<void> deleteRole() => _prefs.removeValue(_roleKey);
}
