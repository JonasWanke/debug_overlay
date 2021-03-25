import 'dart:math';

import 'package:debug_overlay/debug_overlay.dart';
import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final logs = LogCollection();
final mediaOverrideState = ValueNotifier(MediaOverrideState());

final supportedLocales = kMaterialSupportedLanguages
    .sortedBy((it) => it)
    .map((it) => Locale(it))
    .toList();

void main() {
  if (kDebugMode) {
    DebugOverlay.prependHelper(MediaOverrideDebugHelper(
      mediaOverrideState,
      // To support overriding locales, this value must be set and should
      // contain the same locales as passed to [WidgetsApp.supportedLocales],
      // [MaterialApp.supportedLocales] or [CupertinoApp.supportedLocales].
      supportedLocales: supportedLocales,
    ));
    DebugOverlay.appendHelper(LogsDebugHelper(logs));
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MediaOverrideState>(
      valueListenable: mediaOverrideState,
      builder: (context, overrideState, child) => MaterialApp(
        title: '🐛 debug_overlay example',
        themeMode: overrideState.themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        locale: overrideState.locale,
        builder: DebugOverlay.builder(showOnShake: false),
        supportedLocales: supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: HomePage(),
      ),
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
            Text('Current brightness: ${context.theme.brightness}'),
            Text('Current locale: ${context.locale}'),
            SizedBox(height: 16),
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
