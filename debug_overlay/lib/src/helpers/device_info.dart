import 'package:material_ui/material_ui.dart';

import '../debug_helper.dart';
import '../debug_tool.dart';
import 'device_info_io.dart' if (dart.library.js) 'device_info_html.dart';

class const DeviceInfoDebugHelper({super.key}) extends StatelessWidget {
  static const tool = DebugTool(
    icon: Icons.smartphone,
    title: 'Device Info',
    sliver: DeviceInfoDebugHelper(),
  );

  @override
  Widget build(BuildContext context) {
    return DiagnosticsBasedDebugHelper(
      diagnosticsStream: getDiagnostics().asStream(),
    );
  }
}
