/// Number of debaters per team — a fixed app-level invariant.
/// A debate team always has exactly 4 debaters. This is not configurable,
/// not a format setting, and must never be overridden or varied anywhere
/// in the codebase (mock data, UI, business logic).
const int kTeamSize = 3;

/// Total number of debaters in any debate (2 teams × kTeamSize).
const int kDebatersPerDebate = 2 * kTeamSize;

/// Default speaker turn duration in seconds (3 minutes).
const int kSpeakerTurnSeconds = 180;

/// Default preparation room countdown (5 minutes).
const int kPrepRoomCountdownSeconds = 15 * 60;
