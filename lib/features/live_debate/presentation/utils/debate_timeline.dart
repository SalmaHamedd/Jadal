import '../../data/models/debate_models.dart';

/// Visual tier of the main speaker card / timer. All boundaries are
/// derived from [DebateFormat] — no magic numbers.
enum DebateTier { protected, open, extra, timeOff }

/// The six debate-flow moments. Events 1/2/4/5 ring the bell; events
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
/// POI availability follows the **frontend** rules — the backend has no
/// POI field — and the protected/open tiers are derived from the same windows:
/// - **reply speech** → POI never available;
/// - speech **> 3 min** → POI restricted in the first & last **minute**;
/// - speech **1–3 min** → first & last **30 s**;
/// - speech **≤ 1 min** → no POI (the button stays visible but disabled).
/// If [DebateFormat.poiOffset] is ever provided by the backend it overrides the
/// manual rules.
class DebateTimeline {
  final DebateFormat format;
  const DebateTimeline(this.format);

  int get _speech => format.speechDuration.inSeconds;
  int get _extra => format.extraTime.inSeconds;

  /// Main speech ends here.
  int get mainEnd => _speech;

  /// Extra time ends here → Time Off beyond this.
  int get extraEnd => _speech + _extra;

  /// Total seconds tracked by the progress ring (main + extra).
  int get totalTrackedSeconds => extraEnd;

  /// POI protected margin (seconds). The format's configured value wins; the
  /// duration-based rules below are only the fallback when it is absent.
  int get _poiMargin {
    if (format.poiOffset != null) return format.poiOffset!.inSeconds;
    if (_speech <= 60) return _speech; // ≤1 min → no open window at all
    return _speech > 180 ? 60 : 30; // >3 min → 60 s; 1–3 min → 30 s
  }

  /// First instant POIs open.
  int get openWindowStart => _poiMargin;

  /// First instant POIs are closed again (exclusive end of the open window).
  int get openWindowEnd => _speech - _poiMargin;

  /// Whether POIs are available at [elapsed] for this speech.
  bool poiAllowedAt(int elapsed, {bool isReply = false}) {
    if (isReply) return false;
    if (_speech <= 2 * _poiMargin) return false; // window collapses → no POI
    return elapsed >= openWindowStart && elapsed < openWindowEnd;
  }

  /// Back-compat alias used by the cubits.
  bool poiOpenAt(int elapsed, {bool isReply = false}) =>
      poiAllowedAt(elapsed, isReply: isReply);

  DebateTier tierAt(int elapsed, {bool isReply = false}) {
    if (elapsed >= extraEnd) return DebateTier.timeOff;
    if (elapsed >= mainEnd) return DebateTier.extra;
    // A reply has no POI windows → keep it side-coloured (open) throughout.
    if (isReply) return DebateTier.open;
    return poiAllowedAt(elapsed) ? DebateTier.open : DebateTier.protected;
  }

  /// The timeline event occurring exactly at [elapsed] seconds, if any. Ticks
  /// advance one second at a time, so this catches every boundary. POI
  /// boundaries are skipped for reply speeches and ≤1-min speeches.
  DebateTimelineEvent? eventAt(int elapsed, {bool isReply = false}) {
    if (elapsed == 0) return DebateTimelineEvent.speechStarted;
    // A zero protected window is a real setting: POIs are open the whole speech,
    // so there is no moment at which they open or close to announce.
    final hasPoiWindow = !isReply && _poiMargin > 0 && _speech > 2 * _poiMargin;
    if (hasPoiWindow) {
      if (elapsed == openWindowStart) return DebateTimelineEvent.poisOpened;
      if (elapsed == openWindowEnd - 60 && openWindowEnd - 60 > openWindowStart) {
        return DebateTimelineEvent.lastChancePoi;
      }
      if (elapsed == openWindowEnd) return DebateTimelineEvent.poisClosed;
    }
    if (elapsed == mainEnd) return DebateTimelineEvent.mainTimeEnded;
    if (elapsed == extraEnd) return DebateTimelineEvent.extraTimeEnded;
    return null;
  }
}
