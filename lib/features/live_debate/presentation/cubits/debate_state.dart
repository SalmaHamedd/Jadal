part of 'debate_cubit.dart';

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

/// The local user's POI was accepted → show the asker mic dialog (§8.4).
class POIAcceptedForLocalState extends DebateStates {}

class TimerTickedState extends DebateStates {}

/// A debate-flow moment crossed (§8.3 B) — the screen plays the bell and pushes
/// the localized news for [event].
class DebateTimelineEventState extends DebateStates {
  final DebateTimelineEvent event;
  DebateTimelineEventState(this.event);
}

class SpeakerChangedState extends DebateStates {}

class SpeakerOrderChangedState extends DebateStates {}

class LobbyModeChangedState extends DebateStates {}

class TeamChatUpdatedState extends DebateStates {}

class DebateFinishedState extends DebateStates {}
