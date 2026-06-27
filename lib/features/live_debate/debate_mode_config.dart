/// Dev-only switch between the two live-debate modes (§12). There is **no**
/// user-facing dialog — flip the flag here in code.
///
/// >>> To switch which live-debate you see, change [useBackend] below. <<<
///   • false → mock/test peer-to-peer mode ([DebateCubit] + [MockLiveDebateData])
///   • true  → real backend mode ([LiveDebateCubit] driven by REST + LiveKit)
class DebateModeConfig {
  DebateModeConfig._();

  /// false = mock/test mode; true = real backend mode.
  static const bool useBackend = true;

  /// Used only when [useBackend] is true: which debate to load on entry.
  static const int devDebateId = 43;
}
