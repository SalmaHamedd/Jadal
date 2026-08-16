part of 'debate_controller.dart';

abstract class DebateStates {}

class DebateInitialState extends DebateStates {}

class DebateConnectingState extends DebateStates {}

class DebateConnectedState extends DebateStates {}

class DebateErrorState extends DebateStates {
  final String message;
  DebateErrorState(this.message);
}

class DebateDisconnectedState extends DebateStates {
  final String reason;
  DebateDisconnectedState({required this.reason});
}

class LocalTrackUpdatedState extends DebateStates {}

class RemoteTrackReceivedState extends DebateStates {}

class MicToggledState extends DebateStates {}

class CameraToggledState extends DebateStates {}

class NewsUpdatedState extends DebateStates {}

class POIChangedState extends DebateStates {}

/// The local user's POI was accepted → show the asker mic dialog.
class POIAcceptedForLocalState extends DebateStates {}

class TimerTickedState extends DebateStates {}

/// A debate-flow moment crossed — the screen plays the bell and pushes
/// the localized news for [event].
class DebateTimelineEventState extends DebateStates {
  final DebateTimelineEvent event;
  DebateTimelineEventState(this.event);
}

class SpeakerChangedState extends DebateStates {}

class SpeakerOrderChangedState extends DebateStates {}

class LobbyModeChangedState extends DebateStates {}

class TeamChatUpdatedState extends DebateStates {}

/// The chair's next-stage request is in flight → the room shows a blocking
/// loading overlay so a laggy server can't be double-tapped into skipping a
/// speech.
class StageAdvancingChangedState extends DebateStates {}

class DebateFinishedState extends DebateStates {}

/// Backend mode: a fresh `live-state` was fetched and applied — rebuild
/// rooms/teams/judges/result from the new snapshot.
class LiveStateUpdatedState extends DebateStates {}

/// Backend mode: the result was revealed (`result_revealed`). The result room
/// plays the celebratory confetti reveal on this.
class ResultRevealedState extends DebateStates {}

/// The main room was closed without a submitted result → the debate is
/// cancelled. The result room swaps to the cancelled message on this.
class DebateCancelledState extends DebateStates {}

/// Chair moderation publish-lock changed (mute-all / per-user) → widgets
/// re-evaluate whether the local user may open their mic.
class PublishLockChangedState extends DebateStates {}

/// The chair shared the result from the live room → every client navigates to
/// the result screen with confetti.
class NavigateToSharedResultState extends DebateStates {}

/// The chair closed the room → every client is kicked back to the rooms list.
class RoomClosedState extends DebateStates {}

/// The local muted-but-speaking detection flipped (started/stopped catching
/// voice while the mic is off, or the banner was dismissed) → the room shows /
/// hides the push-notification-style banner at the top.
class MutedSpeakingChangedState extends DebateStates {}
