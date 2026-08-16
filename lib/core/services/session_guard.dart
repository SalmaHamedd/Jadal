import 'package:flutter/material.dart';

import '../storage/preferences_database.dart';
import 'session_identity.dart';

/// Handles a token the server no longer accepts.
/// The failure mode this exists for: a stale/rejected token stays on the device
/// after a logout, so the app still *looks* signed in — the shell renders, the
/// user can navigate — but every single API call 401s. The user is trapped in a
/// dead session with no way out except reinstalling.
/// Any repository that sees a **401** must call [onUnauthorized]. It clears the
/// stored credentials and sends the app back to login exactly once, no matter
/// how many in-flight requests fail together.
abstract class SessionGuard {
  /// Set by the app root so a repository (which has no `BuildContext`) can
  /// still navigate. Same key `main.dart` gives `MaterialApp.navigatorKey`.
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Builds the login screen. Injected to keep this file free of feature
  /// imports (auth imports core, not the other way round).
  static WidgetBuilder? loginBuilder;

  /// A burst of parallel 401s must produce ONE logout, not one per request.
  static bool _handling = false;

  /// True once a session has been torn down, so late callbacks can bail out.
  static bool get isSigningOut => _handling;

  static Future<void> onUnauthorized() async {
    if (_handling) return;
    _handling = true;
    try {
      await signOutLocally();
    } finally {
      // Released only after the navigation settles, so the burst that
      // triggered it can't queue a second logout behind this one.
      _handling = false;
    }
  }

  /// Signs out **entirely on the device**: drop the stored credentials and go
  /// to the login screen. No network call.
  /// This is deliberately API-free. It is what runs when the server has
  /// already rejected the session, where `POST /auth/logout` would just fail
  /// with the same 401 that got us here — and a failed request must never be
  /// able to keep a user trapped in a session they asked to leave.
  static Future<void> signOutLocally() async {
    await _clearCredentials();
    final nav = navigatorKey?.currentState;
    final builder = loginBuilder;
    if (nav == null || builder == null) return;
    await nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: builder),
      (route) => false,
    );
  }

  /// Drops everything that identifies the session, in one atomic write.
  /// Tolerant by design: a failure here must not stop the sign-out, or the
  /// user stays stuck.
  static Future<void> _clearCredentials() async {
    try {
      await PreferencesDatabase().removeValues(const [
        'AUTH_TOKEN',
        'user_id',
        // The role is stored under AUTH_ROLE by TokenStorage; clearing a
        // mis-named 'role' key left the previous account's role behind.
        'AUTH_ROLE',
      ]);
    } catch (_) {/* keep going */}
    try {
      await SessionIdentity.clear();
    } catch (_) {/* keep going */}
  }
}
