import 'package:flutter/foundation.dart';

/// A single entry of a [LogCollection].
@immutable
class Log({
  /// The severity; must not be [DiagnosticLevel.off].
  final DiagnosticLevel level = .info,

  /// When the log was created; defaults to now and must be in local time.
  DateTime? timestamp,
  required final String message,

  /// An error or arbitrary data attached to the log.
  ///
  /// If it can be represented as JSON (e.g., via `toJson()`), it can be
  /// inspected as a tree.
  final dynamic error,
  final StackTrace? stackTrace,
}) with Diagnosticable {
  this
    : assert(
        level != .off,
        '`DiagnosticLevel.off` is a "[special] level indicating that no '
        'diagnostics should be shown" and should not be used as a value.',
      ),
      assert(timestamp == null || !timestamp.isUtc),
      timestamp = timestamp ?? DateTime.now();

  final DateTime timestamp;

  @override
  int get hashCode => Object.hash(level, timestamp, message, error, stackTrace);
  @override
  bool operator ==(Object other) {
    return other is Log &&
        level == other.level &&
        timestamp == other.timestamp &&
        message == other.message &&
        error == other.error &&
        stackTrace == other.stackTrace;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty('level', level))
      ..add(DiagnosticsProperty('timestamp', timestamp))
      ..add(StringProperty('message', message))
      ..add(DiagnosticsProperty('error', error))
      ..add(DiagnosticsProperty('stackTrace', stackTrace));
  }
}

/// A bounded list of [Log]s that a `LogsDebugTool` displays, ordered by
/// [Log.timestamp].
///
/// Share one instance between your logging code and the tool.
class LogCollection({
  this._maximumSize = 500,

  /// Whether to only store logs in debug mode.
  final bool onlyStoreLogsInDebugMode = true,
}) {
  final _logs = ValueNotifier(<Log>[]);

  /// Notifies whenever a log is added or removed.
  ValueListenable<List<Log>> get listenable => _logs;

  /// All stored logs, ordered from oldest to newest.
  List<Log> get logs => listenable.value;

  int? _maximumSize;

  /// The maximum number of logs to store or `null` for unlimited storage.
  ///
  /// If more logs arrive, the oldest ones (based on their [Log.timestamp]) will
  /// be removed.
  int? get maximumSize => _maximumSize;
  set maximumSize(int? value) {
    _maximumSize = value;

    if (value != null && logs.length > value) {
      _logs.value = logs.sublist(logs.length - value, logs.length);
    }
  }

  /// Adds [log] at the position given by its timestamp, evicting the oldest
  /// log if [maximumSize] is exceeded.
  void add(Log log) {
    if (onlyStoreLogsInDebugMode && !kDebugMode) return;

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

    var startIndex = 0;
    if (maximumSize != null && logs.length >= maximumSize!) {
      if (index == 0) return;
      startIndex = logs.length - maximumSize! + 1;
    }
    _logs.value = [
      ...logs.sublist(startIndex, index),
      log,
      ...logs.sublist(index, logs.length),
    ];
  }

  /// Removes all stored logs.
  void clear() => _logs.value = [];
}
