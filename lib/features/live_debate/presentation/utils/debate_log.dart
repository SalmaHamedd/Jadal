import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'debate_log_file.dart';

void dlog(String tag, String message) {
  final line = 'JADAL_DEBATE | $tag | $message';
  if (kDebugMode) {
    // ignore: avoid_print
    print(line);
  }
  // Mirror to the file even outside debug so a profile-mode field test still
  // produces a pullable trace. Guarded internally; never throws.
  DebateLogFile.instance.write(line);
}


void dlogJson(String tag, String label, Object? value) {
  String pretty;
  try {
    final decoded = value is String ? jsonDecode(value) : value;
    pretty = const JsonEncoder.withIndent('  ').convert(decoded);
  } catch (_) {
    pretty = value?.toString() ?? 'null';
  }
  dlog(tag, '$label:\n$pretty');
}


void dlogInitFile() => DebateLogFile.instance.init();

/// Absolute path of the on-device trace file (once opened), for an in-app
/// "share log" affordance or to surface in the UI.
String? get debateLogFilePath => DebateLogFile.instance.filePath;
