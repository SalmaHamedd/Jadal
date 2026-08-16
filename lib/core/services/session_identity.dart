import '../storage/preferences_database.dart';

/// The signed-in user's identity, cached at login.
/// The nav drawer used to resolve this with **two** live `GET /profile` calls
/// (one for the header, one for the role gate) plus a third async load for the
/// contact footer, so its items painted at three different times. Everything
/// here already rides on the login response (`data.user`), and the backend has
/// confirmed `points` is read live off the row at login — so the drawer needs
/// no network call at all.
/// Refreshed by [ProfileCubit] whenever a profile load/update succeeds, since
/// points and avatar can change while the app is open.
class SessionIdentity {
  final int id;
  final String name;
  final String role;
  final String? avatarUrl;
  final int points;

  const SessionIdentity({
    required this.id,
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.points,
  });

  static const _kId = 'user_id';
  static const _kName = 'user_name';
  static const _kRole = 'user_role';
  static const _kAvatar = 'user_avatar_url';
  static const _kPoints = 'user_points';

  /// One batched write instead of five separate `setValue` calls, each a
  /// full read-modify-write of the store — and it is called fire-and-forget
  /// from [ProfileCubit], so those writes raced with the token being written
  /// and could drop it. Now it is a single atomic flush.
  static Future<void> cache({
    required int id,
    required String name,
    required String role,
    String? avatarUrl,
    required int points,
  }) => PreferencesDatabase().setValues({
        _kId: id,
        _kName: name,
        _kRole: role,
        _kPoints: points,
        // null removes the key.
        _kAvatar: (avatarUrl == null || avatarUrl.isEmpty) ? null : avatarUrl,
      });

  /// Null when nothing has been cached yet (fresh install, or a session that
  /// predates this cache). Callers render nothing rather than blocking.
  static Future<SessionIdentity?> load() async {
    final prefs = PreferencesDatabase();
    final id = await prefs.getValue<int>(_kId);
    final name = await prefs.getValue<String>(_kName);
    final role = await prefs.getValue<String>(_kRole);
    if (id == null || name == null || role == null) return null;
    return SessionIdentity(
      id: id,
      name: name,
      role: role,
      avatarUrl: await prefs.getValue<String>(_kAvatar),
      points: await prefs.getValue<int>(_kPoints) ?? 0,
    );
  }

  static Future<void> clear() =>
      PreferencesDatabase().removeValues(const [
        _kName,
        _kRole,
        _kAvatar,
        _kPoints,
      ]);
}
