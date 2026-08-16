import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/push_message.dart';
import '../presentation/push_router.dart';
import 'device_repository.dart';

/// Android channel id. MUST match
/// `com.google.firebase.messaging.default_notification_channel_id` in
/// AndroidManifest.xml, or backgrounded pushes land on a different channel
/// than foreground ones and the user sees two entries in system settings.
const String kPushChannelId = 'jadal_default';
const String kPushChannelName = 'Jadal';

/// Background/terminated **data** handler.
/// Must be a top-level function — the Flutter engine spawns a separate
/// isolate for it, so it cannot capture any state from the app. It exists only
/// so data-only messages aren't dropped; anything the user actually sees in
/// this state is drawn by the system from the FCM `notification` block.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Deliberately minimal. Do NOT navigate here: this isolate has no UI, and
  // the tap is delivered separately to onMessageOpenedApp / getInitialMessage.
  debugPrint('[push] background message: ${message.messageId}');
}

/// Owns the whole FCM lifecycle: init, permission, token registration,
/// and the three delivery states a tap can arrive in.
/// Deliberately does NOT depend on any cubit — the auth flow calls
/// [registerToken] / [unregisterToken] at the right moments instead, because
/// only it knows when a bearer token is valid.
class PushService {
  final DeviceRepository _devices;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  PushService({required DeviceRepository devices}) : _devices = devices;

  bool _initialised = false;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  /// Locale last sent to the backend, so a language change can re-register.
  String? _lastLocale;

  /// True once Firebase has started. Everything else no-ops until then, so a
  /// misconfigured build degrades to "no push" rather than crashing on boot.
  bool get isReady => _initialised;

  /// Boot Firebase and wire the message streams. Safe to call more than once.
  /// Never throws: if Firebase can't start (missing or malformed
  /// google-services.json, no Play Services on the device) the app must still
  /// run — push is an enhancement, not a dependency.
  Future<void> init() async {
    if (_initialised) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _initLocalNotifications();
      _wireStreams();
      _initialised = true;
      debugPrint('[push] initialised');
    } catch (e) {
      debugPrint('[push] init FAILED (push disabled this session): $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@drawable/ic_notification');
    // iOS permission is requested explicitly in requestPermission, not here,
    // so the prompt appears at a moment we control.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload);
          if (data is Map) {
            PushRouter.route(
              PushMessage.fromData(data.cast<String, dynamic>()),
            );
          }
        } catch (e) {
          debugPrint('[push] bad local-notification payload: $e');
        }
      },
    );

    // Android 8+ requires the channel to exist before the first notification,
    // otherwise nothing is shown at all.
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            kPushChannelId,
            kPushChannelName,
            importance: Importance.high,
          ),
        );
  }

  void _wireStreams() {
    // 1. Foreground. Android delivers nothing visible in this state, so we
    // draw the notification ourselves to keep it tappable.
    _onMessageSub = FirebaseMessaging.onMessage.listen(_showForeground);

    // 2. Background → tapped. The app is alive, so route immediately.
    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((m) {
      PushRouter.route(PushMessage.fromData(m.data));
    });

    // 3. Token rotation. FCM can rotate at any time; a stale token on the
    // backend means silently undelivered notifications.
    _onTokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final locale = _lastLocale;
      if (locale == null) return; // not logged in — nothing to register against
      await _devices.registerDevice(token: token, locale: locale);
      debugPrint('[push] token refreshed and re-registered');
    });
  }

  /// Cold start: the tap that launched the app. Call once after the navigator
  /// exists (post-splash), or the route is pushed into a navigator that isn't
  /// mounted yet and silently lost.
  Future<void> handleColdStart() async {
    if (!_initialised) return;
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      PushRouter.route(PushMessage.fromData(initial.data));
    }
    // Also replay anything parked before the navigator was ready.
    PushRouter.consumePending();
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return; // data-only: nothing to display
    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          kPushChannelId,
          kPushChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // The data block rides along so the tap can route exactly like a
      // background tap would.
      payload: jsonEncode(message.data),
    );
  }

  /// Ask for notification permission. Android 13+ shows a runtime prompt;
  /// below 33 it is granted at install time. Returns true if we may notify.
  Future<bool> requestPermission() async {
    if (!_initialised) return false;
    final settings = await FirebaseMessaging.instance.requestPermission();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    debugPrint('[push] permission: ${settings.authorizationStatus}');
    return granted;
  }

  /// Register this device against the signed-in user. Call AFTER login, once a
  /// bearer token exists — the endpoint is authenticated.
  /// [locale] is stored server-side and decides which language each push is
  /// sent in, so it must be re-sent whenever the app language changes.
  Future<void> registerToken({required String locale}) async {
    if (!_initialised) return;
    _lastLocale = locale;
    try {
      await requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        debugPrint('[push] no FCM token available');
        return;
      }
      final res = await _devices.registerDevice(token: token, locale: locale);
      res.fold(
        (f) => debugPrint('[push] register failed: ${f.message}'),
        (_) => debugPrint('[push] device registered'),
      );
    } catch (e) {
      debugPrint('[push] register error: $e');
    }
  }

  /// Unregister this device. MUST run while the bearer token is still valid —
  /// the endpoint is scoped to the authenticated caller, so calling it after
  /// the token is cleared 401s and the device keeps receiving pushes for an
  /// account that has logged out.
  Future<void> unregisterToken() async {
    if (!_initialised) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final res = await _devices.unregisterDevice(token);
        res.fold(
          (f) => debugPrint('[push] unregister failed: ${f.message}'),
          (_) => debugPrint('[push] device unregistered'),
        );
      }
      // Drop the local token too, so the next login mints a fresh one rather
      // than reusing one the server has just forgotten.
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('[push] unregister error: $e');
    }
    _lastLocale = null;
  }

  /// Re-send the stored locale after a language switch. No-op when logged out.
  Future<void> updateLocale(String locale) async {
    if (!_initialised || _lastLocale == null || _lastLocale == locale) return;
    await registerToken(locale: locale);
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    await _onTokenRefreshSub?.cancel();
  }
}
