/// Live-debate runs against the real backend only — the old mock/test
/// peer-to-peer mode (and its `useBackend` toggle) has been removed.
class DebateModeConfig {
  DebateModeConfig._();

  /// Fallback debate id used only when a [DebateController] is created without an
  /// explicit id (the normal list → detail → lobby flow always passes a real one).
  static const int devDebateId = 43;
}
