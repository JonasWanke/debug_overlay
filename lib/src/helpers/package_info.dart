import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../debug_helper.dart';
import '../debug_tool.dart';

class const PackageInfoDebugHelper({super.key}) extends StatelessWidget {
  static const tool = DebugTool(
    icon: Icons.inventory_2,
    title: 'Package Info',
    sliver: PackageInfoDebugHelper(),
  );

  @override
  Widget build(BuildContext context) {
    return DiagnosticsBasedDebugHelper(
      title: const Text('Package Info'),
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
