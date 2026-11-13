import 'package:debug_overlay/debug_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026);
  Log log(int seconds) => Log(
    timestamp: start.add(Duration(seconds: seconds)),
    message: 'Log $seconds',
  );
  List<String> messages(LogCollection logs) =>
      logs.logs.map((it) => it.message).toList();

  group('LogCollection', () {
    test('orders logs by timestamp', () {
      final logs = LogCollection()
        ..add(log(2))
        ..add(log(0))
        ..add(log(1));

      expect(messages(logs), ['Log 0', 'Log 1', 'Log 2']);
    });

    test('evicts the oldest log when exceeding maximumSize', () {
      final logs = LogCollection(maximumSize: 2)
        ..add(log(0))
        ..add(log(1))
        ..add(log(2));

      expect(messages(logs), ['Log 1', 'Log 2']);
    });

    test('ignores logs older than all stored logs when full', () {
      final logs = LogCollection(maximumSize: 2)
        ..add(log(1))
        ..add(log(2))
        ..add(log(0));

      expect(messages(logs), ['Log 1', 'Log 2']);
    });

    test('maximumSize setter stores the value and trims logs', () {
      final logs = LogCollection(maximumSize: 5)
        ..add(log(0))
        ..add(log(1))
        ..add(log(2));

      logs.maximumSize = 2;

      expect(logs.maximumSize, 2);
      expect(messages(logs), ['Log 1', 'Log 2']);

      logs.add(log(3));
      expect(messages(logs), ['Log 2', 'Log 3']);
    });

    test('maximumSize can be unlimited', () {
      final logs = LogCollection(maximumSize: 1)
        ..maximumSize = null
        ..add(log(0))
        ..add(log(1));

      expect(logs.maximumSize, isNull);
      expect(logs.logs, hasLength(2));
    });

    test('clear removes all logs', () {
      final logs = LogCollection()
        ..add(log(0))
        ..clear();

      expect(logs.logs, isEmpty);
    });
  });
}
