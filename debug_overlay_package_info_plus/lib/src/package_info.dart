import 'package:debug_overlay/debug_overlay.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PackageInfoDebugTool() extends DiagnosticsBasedDebugTool {
  this : super(icon: Icons.inventory_2, title: 'Package Info');

  late final _diagnostics = _getDiagnostics();

  @override
  Stream<List<DiagnosticsNode>> diagnosticsStream(BuildContext context) {
    return _diagnostics.asStream();
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
