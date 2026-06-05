import '../../data/models/debate_models.dart';

/// Visual tier of the main speaker card / timer (§8.3 B). All boundaries are
/// derived from [DebateFormat] — no magic numbers.
enum DebateTier { protected, open, extra, timeOff }

/// The six debate-flow moments (§8.3 B). Events 1/2/4/5 ring the bell; events
/// 3/6 are news-only.
enum DebateTimelineEvent {
  speechStarted, // opening protected begins — bell
  poisOpened, // first protected ends → POIs open — bell
  lastChancePoi, // one minute until POIs close — news only
  poisClosed, // second protected starts → POIs closed — bell
  mainTimeEnded, // closing protected ends → switch to extra tier — bell
  extraTimeEnded, // extra ends → Time Off — news only
}

extension DebateTimelineEventX on DebateTimelineEvent {
  /// Whether this event rings the protected-boundary bell.
  bool get ringsBell => switch (this) {
        DebateTimelineEvent.speechStarted => true,
        DebateTimelineEvent.poisOpened => true,
        DebateTimelineEvent.poisClosed => true,
        DebateTimelineEvent.mainTimeEnded => true,
        DebateTimelineEvent.lastChancePoi => false,
        DebateTimelineEvent.extraTimeEnded => false,
      };
}

/// Pure state machine for a single speech, driven entirely by [DebateFormat].
class DebateTimeline {
  final DebateFormat format;
  const DebateTimeline(this.format);

  int get _protected => format.protectedPeriod.inSeconds;
  int get _speech => format.speechDuration.inSeconds;
  int get _extra => format.extraTime.inSeconds;

  /// Opening protected window: [0, openingProtectedEnd).
  int get openingProtectedEnd => _protected;

  /// Closing protected window: [poiCloseStart, mainEnd).
  int get poiCloseStart => _speech - _protected;

  /// Main speech ends here (closing protected also ends).
  int get mainEnd => _speech;

  /// Extra time ends here → Time Off beyond this.
  int get extraEnd => _speech + _extra;

  /// Total seconds tracked by the progress ring (main + extra).
  int get totalTrackedSeconds => extraEnd;

  DebateTier tierAt(int elapsed) {
    if (elapsed >= extraEnd) return DebateTier.timeOff;
    if (elapsed >= mainEnd) return DebateTier.extra;
    if (elapsed < openingProtectedEnd) return DebateTier.protected;
    if (elapsed >= poiCloseStart) return DebateTier.protected;
    return DebateTier.open;
  }

  /// POIs are available only in the open window
  /// [openingProtectedEnd, poiCloseStart).
  bool poiOpenAt(int elapsed) => tierAt(elapsed) == DebateTier.open;

  /// The timeline event occurring exactly at [elapsed] seconds, if any. Ticks
  /// advance one second at a time, so this catches every boundary.
  DebateTimelineEvent? eventAt(int elapsed) {
    if (elapsed == 0) return DebateTimelineEvent.speechStarted;
    if (elapsed == openingProtectedEnd) return DebateTimelineEvent.poisOpened;
    if (elapsed == poiCloseStart - 60 && poiCloseStart - 60 > openingProtectedEnd) {
      return DebateTimelineEvent.lastChancePoi;
    }
    if (elapsed == poiCloseStart) return DebateTimelineEvent.poisClosed;
    if (elapsed == mainEnd) return DebateTimelineEvent.mainTimeEnded;
    if (elapsed == extraEnd) return DebateTimelineEvent.extraTimeEnded;
    return null;
  }
}
