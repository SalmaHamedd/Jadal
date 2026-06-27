import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'debate_log_file.dart';

/// Verbose tracing for the live-debate lifecycle (open details → join → connect →
/// data-channel events → stage flow → role/presence → backend payloads).
///
/// Every line is prefixed with `JADAL_DEBATE` so the whole trace can be grepped
/// out of the run console. In addition to the console, every line is mirrored to
/// an on-device file ([DebateLogFile]) — the console truncates long lines (a full
/// `live-state` JSON), the file does not — so the raw backend/socket data is
/// captured in full for sharing/diagnosis.
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

/// Logs a (potentially large) JSON payload in full under [tag]/[label].
///
/// This is the "really show the response" channel the diagnosis relies on: the
/// raw body fetched from the backend or received on the socket, pretty-printed so
/// it's readable in the file (the console may still truncate — read the file for
/// the complete object). [value] may be a decoded `Map`/`List`, a raw JSON
/// string, or anything else (logged via `toString`).
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

/// Ensures the on-device log file is opened (and its path printed) eagerly —
/// call this the moment the user enters the debate-details/live flow so the very
/// first lines are captured and the tester sees the file path immediately.
void dlogInitFile() => DebateLogFile.instance.init();

/// Absolute path of the on-device trace file (once opened), for an in-app
/// "share log" affordance or to surface in the UI.
String? get debateLogFilePath => DebateLogFile.instance.filePath;
