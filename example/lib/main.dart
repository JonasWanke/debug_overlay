import 'dart:math';

import 'package:debug_overlay/debug_overlay.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final logs = LogCollection();

void main() {
  if (kDebugMode) {
    DebugOverlay.appendHelper(LogsDebugHelper(logs));
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🐛 debug_overlay example',
      themeMode: ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      builder: DebugOverlay.builder(showOnShake: false),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  static final _random = Random();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🐛 debug_overlay example')),
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _createLog,
              child: Text('Add log'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: DebugOverlay.show,
              child: Text('Show Debug Overlay'),
            ),
          ],
        ),
      ),
    );
  }

  void _createLog() {
    // The last value is `off`, which should only be used for filtering.
    final level = DiagnosticLevel
        .values[_random.nextInt(DiagnosticLevel.values.length - 1)];
    final hasError = _random.nextBool();
    final log = Log(
      level: level,
      message: 'Log entry #${logs.logs.length + 1}',
      tags: {
        if (_random.nextDouble() >= 0.3) 'foo',
        if (_random.nextDouble() >= 0.6) 'bar',
      },
      error: hasError ? ArgumentError.value('bar', 'foo') : null,
      stackTrace: hasError ? StackTrace.current : null,
    );
    logs.add(log);
  }
}
