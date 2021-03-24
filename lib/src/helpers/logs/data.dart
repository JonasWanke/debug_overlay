import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class Log {
  Log({
    this.level = DiagnosticLevel.info,
    DateTime? timestamp,
    required this.message,
    this.tags = const {},
    this.error,
    this.stackTrace,
  })  : assert(
          level != DiagnosticLevel.off,
          '`DiagnosticLevel.off` is a "[special] level indicating that no '
          'diagnostics should be shown" and should not be used as a value.',
        ),
        assert(timestamp == null || !timestamp.isUtc),
        timestamp = timestamp ?? DateTime.now();

  final DiagnosticLevel level;
  final DateTime timestamp;
  final String message;
  final Set<String> tags;
  final dynamic? error;
  final StackTrace? stackTrace;

  @override
  int get hashCode =>
      hashValues(level, timestamp, message, tags, error, stackTrace);

  @override
  bool operator ==(Object other) {
    return other is Log &&
        level == other.level &&
        timestamp == other.timestamp &&
        message == other.message &&
        tags == other.tags &&
        error == other.error &&
        stackTrace == other.stackTrace;
  }
}

class LogCollection {
  final _logs = ValueNotifier<List<Log>>([]);
  ValueListenable<List<Log>> get listenable => _logs;
  List<Log> get logs => listenable.value;

  void add(Log log) {
    int index;
    if (logs.isEmpty || !log.timestamp.isBefore(logs.last.timestamp)) {
      // Quick path as new logs are usually more recent.
      index = logs.length;
    } else {
      // Binary search to find the insertion index.
      var min = 0;
      var max = logs.length;
      while (min < max) {
        final mid = min + ((max - min) >> 1);
        final item = logs[mid];
        if (log.timestamp.isBefore(item.timestamp)) {
          max = mid;
        } else {
          min = mid + 1;
        }
      }
      assert(min == max);
      index = min;
    }

    _logs.value = [
      ...logs.sublist(0, index),
      log,
      ...logs.sublist(index, logs.length),
    ];
  }
}
