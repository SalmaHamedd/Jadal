import 'package:audioplayers/audioplayers.dart';

/// Lightweight bell used at the four protected-period boundaries (§8.3 B).
///
/// Guarded: if `assets/sounds/bell.mp3` is missing (or audio fails on the
/// platform), playback errors are swallowed so the debate flow never breaks.
/// Drop a `bell.mp3` into `assets/sounds/` to hear it.
class DebateBell {
  DebateBell._();
  static final DebateBell instance = DebateBell._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> ring() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/bell.mp3'));
    } catch (_) {
      // No-op: missing asset or unsupported platform.
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
