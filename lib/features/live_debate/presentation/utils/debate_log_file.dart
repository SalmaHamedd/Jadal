import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Mirrors every `dlog(...)` line to a file on the device so a tester can pull
/// the full live-debate trace off it.
///
/// A file rather than the console because logcat truncates very long lines,
/// which is exactly where a `live-state` body matters most.
///
/// Opens lazily on the first write, buffers anything logged before the path
/// resolves, serialises writes so lines can't interleave, and never throws
/// back into the caller.
class DebateLogFile {
  DebateLogFile._();
  static final DebateLogFile instance = DebateLogFile._();

  /// One rolling file across sessions; each run appends a `new session` header so
  /// older runs stay readable above the latest one.
  static const String fileName = 'jadal_live_debate_log.txt';

  File? _file;

  /// Absolute path of the log file once opened — printed at startup so the tester
  /// knows exactly where to pull it from (also exposed for an in-app "share log").
  String? filePath;

  bool _starting = false;
  final List<String> _pending = <String>[];
  Future<void> _chain = Future<void>.value();

  bool get isReady => _file != null;

  /// Resolve a writable path and open the file (append). Safe to call any number
  /// of times; only the first call does the work. Writes a session header so the
  /// latest run is easy to find.
  Future<void> init() async {
    if (_starting || _file != null) return;
    _starting = true;
    try {
      final dir = await _resolveDir();
      final f = File('${dir.path}/$fileName');
      await f.create(recursive: true);
      final header = '\n========== JADAL LIVE DEBATE — new session '
          '${DateTime.now().toIso8601String()} ==========';
      await f.writeAsString('$header\n', mode: FileMode.append, flush: true);
      _file = f;
      filePath = f.path;
      if (kDebugMode) {
        // ignore: avoid_print
        print('JADAL_DEBATE | logfile | writing FULL trace to: ${f.path}');
      }
      // Flush anything buffered before the file opened, preserving order by
      // routing it through the same write chain.
      if (_pending.isNotEmpty) {
        final buffered = _pending.join();
        _pending.clear();
        _enqueue(buffered);
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('JADAL_DEBATE | logfile | could NOT open log file: $e');
      }
    } finally {
      _starting = false;
    }
  }

  /// Prefer a spot a tester can actually reach (file manager / `adb pull`):
  /// app-scoped external storage on Android, the documents dir everywhere else.
  Future<Directory> _resolveDir() async {
    try {
      if (Platform.isAndroid) {
        final ext = await getExternalStorageDirectory();
        if (ext != null) return ext;
      }
    } catch (_) {/* fall through to documents */}
    return getApplicationDocumentsDirectory();
  }

  /// Append one already-formatted line (a timestamp is prefixed here). Buffers
  /// until the file is open, then serializes the write. Never throws.
  void write(String line) {
    final entry = '${DateTime.now().toIso8601String()}  $line\n';
    if (_file == null) {
      _pending.add(entry);
      init(); // kick off lazy open on the very first line, regardless of caller
      return;
    }
    _enqueue(entry);
  }

  void _enqueue(String text) {
    final f = _file;
    if (f == null) {
      _pending.add(text);
      return;
    }
    _chain = _chain.then((_) async {
      try {
        await f.writeAsString(text, mode: FileMode.append, flush: true);
      } catch (_) {/* swallow — logging must never break the app */}
    });
  }
}
