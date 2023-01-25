import 'package:flutter/widgets.dart';

import '../debug_helper.dart';
import 'device_info_io.dart' if (dart.library.js) 'device_info_html.dart';

class DeviceInfoDebugHelper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DiagnosticsBasedDebugHelper(
      title: const Text('Device Info'),
      // ignore: discarded_futures, https://github.com/dart-lang/linter/issues/3429
      diagnosticsStream: getDiagnostics().asStream(),
    );
  }
}
