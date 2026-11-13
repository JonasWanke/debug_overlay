import 'package:debug_overlay/debug_overlay.dart';
import 'package:material_ui/material_ui.dart';

import 'device_info_io.dart'
    if (dart.library.js_interop) 'device_info_html.dart';

/// A [DiagnosticsBasedDebugTool] that shows information about the device and
/// its operating system.
class DeviceInfoDebugTool() extends DiagnosticsBasedDebugTool {
  this : super(icon: Icons.smartphone, title: 'Device Info');

  late final _diagnostics = getDiagnostics();

  @override
  Stream<List<DiagnosticsNode>> diagnosticsStream(BuildContext context) {
    return _diagnostics.asStream();
  }
}
