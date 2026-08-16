import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../features/live_debate/presentation/pages/backend_debate_detail_screen.dart';
import '../../features/live_debate/presentation/pages/guest_debate_screen.dart';
import '../../features/notifications/presentation/push_router.dart';
import 'token_storage.dart';

/// Handles `https://jadal-platform.com/d/{id}` debate links.
/// A signed-in user lands on the normal debate details screen and keeps their
/// real role. Someone without a stored token goes straight into the main room
/// as a watch-only guest.
class DeepLinkService {
  DeepLinkService();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  /// A link that arrived before the navigator was mounted (cold start).
  /// Replayed once by [consumePending] after the splash resolves.
  static Uri? _pending;

  /// Path segment the backend uses for share links.
  static const String _debateSegment = 'd';

  Future<void> init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _pending = initial;
      _subscription = _appLinks.uriLinkStream.listen(
        handle,
        onError: (_) {},
      );
    } catch (_) {
      // Deep links are an entry point, not a dependency — if the platform
      // channel is unavailable the app still runs normally.
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Reads the debate id out of a share link, or null if it isn't one.
  static int? debateIdFrom(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final index = segments.indexOf(_debateSegment);
    if (index == -1 || index + 1 >= segments.length) return null;
    return int.tryParse(segments[index + 1]);
  }

  /// Routes a link now, or parks it if the navigator isn't mounted yet.
  static void handle(Uri uri) {
    final debateId = debateIdFrom(uri);
    if (debateId == null) return;
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      _pending = uri;
      return;
    }
    unawaited(_openDebate(navigator, debateId));
  }

  /// Replays a parked cold-start link. Safe to call unconditionally.
  static void consumePending() {
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    handle(pending);
  }

  static Future<void> _openDebate(NavigatorState navigator, int debateId) async {
    final token = await TokenStorage.getToken();
    final signedIn = token != null && token.trim().isNotEmpty;
    if (!navigator.mounted) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => signedIn
            ? BackendDebateDetailScreen(debateId: debateId)
            : GuestDebateScreen(debateId: debateId),
      ),
    );
  }
}
