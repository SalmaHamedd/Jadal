// ============================================================================
// ====================  PASTE YOUR LIVEKIT TEST CREDENTIALS HERE  =============
// ============================================================================
//
// For testing (§7): create a room on the LiveKit website and paste the
// generated URL + token below. The debate room screen connects with these on
// init (see DebateRoomScreen / DebateCubit.connectToRoom). Do NOT scatter
// credentials anywhere else in the app.
//
//   kLiveKitUrl   -> e.g. wss://xxxx.livekit.cloud
//   kLiveKitToken -> the access token generated on the LiveKit website
//
// ============================================================================

const String kLiveKitUrl = 'wss://flutterpoi-ar6hq9rt.livekit.cloud'; // e.g. wss://xxxx.livekit.cloud
const String kLiveKitToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3ODk1MjEwNjAsImlkZW50aXR5IjoiRWJhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWEiLCJpc3MiOiJBUElBS2hvekJKTHVrSnEiLCJuYmYiOjE3ODA1MjEwNjAsInN1YiI6IkViYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhIiwidmlkZW8iOnsiY2FuUHVibGlzaCI6dHJ1ZSwiY2FuUHVibGlzaERhdGEiOnRydWUsImNhblN1YnNjcmliZSI6dHJ1ZSwicm9vbSI6IkRlYmF0ZS0xIiwicm9vbUpvaW4iOnRydWV9fQ.s0blM7VcpRebWkB8qbkp56dkIKR9T2_qBffMvCdmnc4'; // token generated on the LiveKit website

/// True once both values above are filled in. When false, the debate screen
/// still renders fully (timer, layout, mock data) but skips the live connect.
bool get kHasLiveKitCredentials =>
    kLiveKitUrl.trim().isNotEmpty && kLiveKitToken.trim().isNotEmpty;
