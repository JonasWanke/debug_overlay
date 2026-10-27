import 'package:debug_overlay/debug_overlay.dart';
import 'package:material_ui/material_ui.dart';

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
