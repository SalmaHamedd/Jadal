import 'package:flutter/foundation.dart';

/// Temporary verbose tracing for the live-debate lifecycle (join → connect →
/// data-channel events → stage flow → role/presence resolution).
///
/// Every line is prefixed with `JADAL_DEBATE` so the whole trace can be grepped
/// out of the run console and these calls removed in one pass later. Guarded by
/// [kDebugMode] so nothing leaks into release builds.
void dlog(String tag, String message) {
  if (kDebugMode) {
    // ignore: avoid_print
    print('JADAL_DEBATE | $tag | $message');
  }
}
