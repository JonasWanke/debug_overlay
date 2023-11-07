import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../debug_helper.dart';

class PackageInfoDebugHelper extends StatelessWidget {
  const PackageInfoDebugHelper({super.key});

  @override
  Widget build(BuildContext context) {
    return DiagnosticsBasedDebugHelper(
      title: const Text('Package Info'),
      // ignore: discarded_futures, https://github.com/dart-lang/linter/issues/3429
      diagnosticsStream: _getDiagnostics().asStream(),
    );
  }

  Future<List<DiagnosticsNode>> _getDiagnostics() async {
    final info = await PackageInfo.fromPlatform();
    return [
      StringProperty('App Name', info.appName),
      StringProperty('Package Name', info.packageName),
      StringProperty('Version', info.version),
      StringProperty('Build Number', info.buildNumber),
    ];
  }
}
