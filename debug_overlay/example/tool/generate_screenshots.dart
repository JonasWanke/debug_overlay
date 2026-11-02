// Generates the screenshots in the `doc` directories of all packages, which are
// used in their READMEs and on pub.dev.
//
// Run from `debug_overlay/example`:
//
//     flutter test tool/generate_screenshots.dart
//
// To add a screenshot, append an entry to `_screenshots` below.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:debug_overlay/debug_overlay.dart';
import 'package:debug_overlay_device_info_plus/debug_overlay_device_info_plus.dart';
import 'package:debug_overlay_file_browser/debug_overlay_file_browser.dart';
import 'package:debug_overlay_package_info_plus/debug_overlay_package_info_plus.dart';
import 'package:debug_overlay_shared_preferences/debug_overlay_shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_info_plus_platform_interface/device_info_plus_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _width = 400.0;
const _pixelRatio = 2.0;

void main() {
  setUpAll(_loadFonts);
  setUpAll(_createFileBrowserFixture);
  tearDownAll(_deleteFileBrowserFixture);

  for (final screenshot in _screenshots) {
    testWidgets(
      'Screenshot ${screenshot.path}',
      skip: screenshot.skip != null,
      (tester) async {
        tester.view
          ..physicalSize = Size(_width, screenshot.height) * _pixelRatio
          ..devicePixelRatio = _pixelRatio;
        addTearDown(tester.view.reset);

        final tool = screenshot.tool();
        DebugOverlay.tools.value = [tool];
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData.light(),
              home: const Scaffold(body: DebugOverlayContent()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await screenshot.prepare?.call(tester);

        await _save(tester, boundaryKey, screenshot.path);
      },
    );
  }
}

class _Screenshot(
  /// The directory name of the package that the screenshot belongs to.
  final String package,
  final String fileName,
  final DebugTool Function() tool, {

  /// Logical height of the screenshot; the width is always [_width].
  final double height = 320,

  /// Brings the tool into the state to be captured, e.g., by tapping on it.
  final Future<void> Function(WidgetTester tester)? prepare,

  /// If non-`null`, the screenshot is skipped and this explains why.
  final String? skip,
}) {
  /// The path relative to `debug_overlay/example`.
  String get path => '../../$package/doc/$fileName';
}

final _screenshots = [
  _Screenshot(
    'debug_overlay',
    'helpers-mediaQuery.png',
    () => MediaQueryDebugHelper.tool,
  ),
  _Screenshot(
    'debug_overlay',
    'helpers-logs.png',
    () => LogsDebugHelper.tool(_sampleLogs()),
    height: 360,
  ),
  _Screenshot(
    'debug_overlay',
    'helpers-mediaOverrides.png',
    () => MediaOverrideDebugHelper.tool(
      ValueNotifier(MediaOverrideState()),
      supportedLocales: [
        const Locale('de'),
        const Locale('en', 'US'),
        const Locale('fr'),
      ],
    ),
  ),
  _Screenshot(
    'debug_overlay',
    'helpers-network.png',
    () => NetworkDebugHelper.tool(_sampleRequests()),
    height: 400,
  ),
  _Screenshot(
    'debug_overlay',
    'helpers-rendering.png',
    () => RenderingDebugHelper.tool,
    height: 560,
  ),

  // The packages for HTTP clients only record requests, which are shown by the
  // network tool.
  for (final package in ['debug_overlay_http', 'debug_overlay_dio'])
    _Screenshot(
      package,
      'helpers-network.png',
      () => NetworkDebugHelper.tool(_sampleRequests()),
      height: 400,
    ),

  _Screenshot(
    'debug_overlay_device_info_plus',
    'helpers-deviceInfo.png',
    _deviceInfoTool,
    // The tool reads the info of the platform that the test runs on, and we
    // only fake the Linux one.
    skip: Platform.isLinux ? null : 'Only supported when running on Linux.',
  ),
  _Screenshot(
    'debug_overlay_package_info_plus',
    'helpers-packageInfo.png',
    _packageInfoTool,
  ),
  _Screenshot(
    'debug_overlay_shared_preferences',
    'helpers-sharedPreferences.png',
    _sharedPreferencesTool,
    height: 500,
  ),
  _Screenshot(
    'debug_overlay_file_browser',
    'helpers-fileBrowser.png',
    _fileBrowserTool,
    height: 560,
    prepare: (tester) async {
      await tester.tap(find.text('Documents'));
      // Real file system access isn't driven by the test's fake clock, so we
      // alternate between waiting for it and processing the results.
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
    },
    skip: Platform.isWindows ? 'The fixture lives in `/tmp`.' : null,
  ),
];

LogCollection _sampleLogs() {
  final start = DateTime(2025, 1, 1, 11, 24, 10, 146);
  final logs = LogCollection();
  const levels = [
    DiagnosticLevel.warning,
    DiagnosticLevel.debug,
    DiagnosticLevel.info,
    DiagnosticLevel.error,
  ];
  for (final (index, level) in levels.indexed) {
    final isError = level == DiagnosticLevel.error;
    logs.add(
      Log(
        level: level,
        timestamp: start.add(Duration(milliseconds: 170 * index)),
        message: 'Log entry #${index + 1}',
        error: isError ? ArgumentError.value('bar', 'foo') : null,
        stackTrace: isError ? StackTrace.fromString(_sampleStackTrace) : null,
      ),
    );
  }
  return logs;
}

const _sampleStackTrace = '''
#0      HomePage._createLog (package:debug_overlay_example/main.dart:114:41)
#1      _InkResponseState.handleTap (package:flutter/src/material/ink_well.dart:1176:21)
#2      GestureRecognizer.invokeCallback (package:flutter/src/gestures/recognizer.dart:351:24)''';

NetworkRequestCollection _sampleRequests() {
  final start = DateTime(2025, 1, 1, 11, 24, 10, 146);
  NetworkRequest request(
    int id,
    String method,
    String path, {
    int? statusCode,
    String? reasonPhrase,
    required int milliseconds,
    Object? error,
  }) {
    return NetworkRequest(
      id: id,
      method: method,
      url: Uri.parse('https://example.com/$path'),
      startTime: start.add(Duration(milliseconds: 400 * id)),
      statusCode: statusCode,
      reasonPhrase: reasonPhrase,
      duration: Duration(milliseconds: milliseconds),
      error: error,
    );
  }

  return _FixedNetworkRequests([
    request(
      0,
      'GET',
      'api/users',
      statusCode: 200,
      reasonPhrase: 'OK',
      milliseconds: 120,
    ),
    request(
      1,
      'POST',
      'api/users',
      statusCode: 201,
      reasonPhrase: 'Created',
      milliseconds: 340,
    ),
    request(
      2,
      'GET',
      'api/missing',
      statusCode: 404,
      reasonPhrase: 'Not Found',
      milliseconds: 85,
    ),
    request(
      3,
      'GET',
      'api/unreachable',
      milliseconds: 3000,
      error: const SocketException('Connection refused'),
    ),
  ]);
}

/// A [NetworkRequestCollection] with predefined requests, so that the
/// screenshots don't depend on the current time.
class _FixedNetworkRequests extends NetworkRequestCollection {
  _FixedNetworkRequests(List<NetworkRequest> requests)
    : _listenable = ValueNotifier(requests);

  final ValueNotifier<List<NetworkRequest>> _listenable;

  @override
  ValueListenable<List<NetworkRequest>> get listenable => _listenable;
}

DebugTool _deviceInfoTool() {
  DeviceInfoPlatform.instance = _FakeDeviceInfoPlatform();
  return DeviceInfoDebugHelper.tool;
}

class _FakeDeviceInfoPlatform extends DeviceInfoPlatform {
  @override
  Future<BaseDeviceInfo> deviceInfo() async {
    return LinuxDeviceInfo(
      name: 'Ubuntu',
      version: '24.04.1 LTS (Noble Numbat)',
      id: 'ubuntu',
      idLike: ['debian'],
      versionCodename: 'noble',
      versionId: '24.04',
      prettyName: 'Ubuntu 24.04.1 LTS',
      machineId: '0123456789abcdef0123456789abcdef',
    );
  }
}

DebugTool _packageInfoTool() {
  // This script runs as a test, but isn't located in a test directory.
  // ignore: invalid_use_of_visible_for_testing_member
  PackageInfo.setMockInitialValues(
    appName: 'My App',
    packageName: 'com.example.my_app',
    version: '1.2.3',
    buildNumber: '42',
    buildSignature: '',
  );
  return PackageInfoDebugHelper.tool;
}

DebugTool _sharedPreferencesTool() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData({
        'launch_count': 42,
        'onboarding_completed': true,
        'recent_searches': ['flutter', 'dart'],
        'theme_mode': 'dark',
        'ui_scale': 1.25,
      });
  return SharedPreferencesDebugHelper.tool();
}

// The directory is shown in the screenshot, so it needs a stable path.
final _fileBrowserDirectory = Directory('/tmp/debug_overlay_screenshots');

void _createFileBrowserFixture() {
  _deleteFileBrowserFixture();

  final documents = Directory('${_fileBrowserDirectory.path}/documents')
    ..createSync(recursive: true);
  // The size and modification time are shown, so they must not change between
  // runs.
  final modified = DateTime(2025, 1, 1, 11, 24, 10);
  for (final (name, size) in [
    ('app.log', 4711),
    ('cache.db', 12 * 1024),
    ('config.json', 512),
    ('notes.txt', 87),
  ]) {
    File('${documents.path}/$name')
      ..writeAsBytesSync(List.filled(size, 0x61))
      ..setLastModifiedSync(modified);
  }
}

void _deleteFileBrowserFixture() {
  if (_fileBrowserDirectory.existsSync()) {
    _fileBrowserDirectory.deleteSync(recursive: true);
  }
}

DebugTool _fileBrowserTool() {
  return FileBrowserDebugHelper.tool(
    roots: [
      FileBrowserRoot(
        name: 'Documents',
        directory: Directory('${_fileBrowserDirectory.path}/documents'),
      ),
    ],
  );
}

Future<void> _save(WidgetTester tester, GlobalKey key, String path) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
  });
}

/// Flutter's test environment renders all text in a placeholder font unless
/// real fonts are loaded.
Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  Future<ByteData> read(String path) async {
    final bytes = await File(path).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  if (flutterRoot != null) {
    final fonts = '$flutterRoot/bin/cache/artifacts/material_fonts';
    final roboto = FontLoader('Roboto');
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      roboto.addFont(read('$fonts/Roboto-$weight.ttf'));
    }
    await roboto.load();

    final icons = FontLoader('MaterialIcons')
      ..addFont(read('$fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  } else {
    debugPrint('FLUTTER_ROOT is not set; text will use a placeholder font.');
  }
}
