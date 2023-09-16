import 'package:data_size/data_size.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

Future<List<DiagnosticsNode>> getDiagnostics() async {
  assert(kIsWeb);

  final info = await DeviceInfoPlugin().webBrowserInfo;
  final deviceMemory = info.deviceMemory;
  return [
    StringProperty('Platform', 'Web Browser'),
    DiagnosticsBlock(
      name: 'Browser: ${info.browserName.name}',
      properties: [
        StringProperty(
          'Vendor',
          info.vendor,
          level: DiagnosticLevel.fine,
        ),
        StringProperty(
          'Vendor Version',
          info.vendorSub,
          defaultValue: '',
          level: DiagnosticLevel.fine,
        ),
        StringProperty(
          'Codename',
          info.appCodeName,
          level: DiagnosticLevel.fine,
        ),
        StringProperty(
          'Version',
          info.appVersion,
          level: DiagnosticLevel.fine,
        ),
        StringProperty(
          'Build Number',
          info.productSub,
          level: DiagnosticLevel.fine,
        ),
      ],
    ),
    StringProperty('Language', info.language),
    IterableProperty<dynamic>('Languages', info.languages),
    StringProperty('User Agent', info.userAgent),
    IntProperty(
      'Maximum Simultaneous Touch Points',
      info.maxTouchPoints,
      defaultValue: 0,
    ),
    IntProperty('Logical CPU Cores', info.hardwareConcurrency),
    // The doc comment says gigabytes, but it's actually imprecise gibibytes…
    if (deviceMemory != null)
      StringProperty(
        'Memory Size',
        (deviceMemory * 1024 * 1024 * 1024)
            .formatByteSize(prefix: Prefix.binary),
      ),
  ];
}
