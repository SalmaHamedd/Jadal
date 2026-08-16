import 'package:flutter/material.dart';

import '../../blog/presentation/screens/all_blogs_screen.dart';
import '../../live_debate/presentation/pages/backend_debate_detail_screen.dart';
import '../../surveys/presentation/screens/survey_details_screen.dart';
import '../../teams/presentation/screens/team_info_screen.dart';
import '../domain/push_message.dart';

/// Navigator key for the app's root [MaterialApp].
/// Notification taps arrive from outside the widget tree — including on a cold
/// start, where no screen has built yet — so routing cannot rely on a
/// BuildContext from the tap site.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Opens the screen a [PushMessage] points at.
/// Handles all three delivery states the same way: foreground, background, and
/// cold start. Cold start is why [pendingColdStartMessage] exists — a tap that
/// launches the app fires before the navigator is mounted, so it is parked and
/// replayed once the app reaches its first real screen.
class PushRouter {
  const PushRouter._();

  /// A cold-start tap held until the navigator exists. Consumed exactly once by
  /// [consumePending] after the splash resolves.
  static PushMessage? pendingColdStartMessage;

  /// Park a message that arrived before the navigator was ready.
  static void holdForColdStart(PushMessage message) {
    pendingColdStartMessage = message;
  }

  /// Replay a parked cold-start tap, if any. Safe to call unconditionally.
  static void consumePending() {
    final pending = pendingColdStartMessage;
    if (pending == null) return;
    pendingColdStartMessage = null;
    route(pending);
  }

  /// Push the destination for [message]. A no-op if the navigator isn't
  /// mounted yet — callers in that situation should use [holdForColdStart].
  static void route(PushMessage message) {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      holdForColdStart(message);
      return;
    }

    final builder = _builderFor(message);
    // Home means "nothing specific to open" — the app is already there after a
    // cold start, and interrupting the user mid-screen would be worse than
    // doing nothing.
    if (builder == null) return;
    navigator.push(MaterialPageRoute(builder: builder));
  }

  static WidgetBuilder? _builderFor(PushMessage message) {
    final id = message.entityId;
    switch (message.destination) {
      case PushDestination.debateDetails:
        return (_) => BackendDebateDetailScreen(debateId: id!);
      case PushDestination.survey:
        return (_) => SurveyDetailsScreen(surveyId: id!);
      case PushDestination.team:
        // Only the id travels in the payload; TeamInfoScreen fetches the rest
        // itself when no initialTeam is supplied, so an empty name is correct
        // rather than a guess.
        return (_) => TeamInfoScreen(teamId: id!, teamName: '');
      case PushDestination.blog:
        return (_) => const AllBlogsScreen();
      case PushDestination.home:
        return null;
    }
  }
}
