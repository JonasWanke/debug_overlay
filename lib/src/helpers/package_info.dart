import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../debug_helper.dart';

class PackageInfoDebugHelper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DiagnosticsBasedDebugHelper(
      title: Text('Package Info'),
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
