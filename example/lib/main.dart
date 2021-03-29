import 'dart:math';

import 'package:debug_overlay/debug_overlay.dart';
import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// By default, this only stores the last 50 logs. You can customize this via the
// `maximumSize` parameter.
//
// Logs are only stored in debug builds.
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
      // contain the same locales as passed to [MaterialApp.supportedLocales],
      // [CupertinoApp.supportedLocales] or [WidgetsApp.supportedLocales].
      supportedLocales: supportedLocales,
    ));
    DebugOverlay.appendHelper(LogsDebugHelper(logs));
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // To use the [MediaOverrideDebugHelper], wrap your app in a
    // [ValueListenableBuilder] to access the overridden values:
    return ValueListenableBuilder<MediaOverrideState>(
      valueListenable: mediaOverrideState,
      builder: (context, overrideState, child) {
        return MaterialApp(
          title: '🐛 debug_overlay example',

          // You can access overridden values via [overrideState]:
          themeMode: overrideState.themeMode,
          locale: overrideState.locale,

          // This creates the actual [DebugOverlay] (only in debug mode; not in
          // profile oder release mode).
          builder: DebugOverlay.builder(showOnShake: true),

          // And the usual customization:
          supportedLocales: supportedLocales,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: HomePage(),
        );
      },
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
            Text('Brightness: ${context.theme.brightness}'),
            SizedBox(height: 4),
            Text('Locale: ${context.locale}'),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => _createLog(),
              child: Text('Add log'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => DebugOverlay.show(),
              child: Text('Show Debug Overlay'),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a single log randomly and appends it to [logs].
  void _createLog() {
    // The last value is `off`, which should only be used for filtering.
    final level = DiagnosticLevel
        .values[_random.nextInt(DiagnosticLevel.values.length - 1)];
    final hasError = _random.nextDouble() >= 0.8;
    final log = Log(
      level: level,
      message: 'Log entry #${logs.logs.length + 1}',
      error: hasError ? ArgumentError.value('bar', 'foo') : null,
      stackTrace: hasError ? StackTrace.current : null,
    );

    // If you use a custom logging solution, you have to also append logs to
    // `debug_overlay`'s LogCollection.
    logs.add(log);
  }
}

// ignore_for_file: unnecessary_lambdas
