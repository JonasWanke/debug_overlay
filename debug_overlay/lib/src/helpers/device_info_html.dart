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
        StringProperty('Vendor', info.vendor, level: .fine),
        StringProperty(
          'Vendor Version',
          info.vendorSub,
          defaultValue: '',
          level: .fine,
        ),
        StringProperty('Codename', info.appCodeName, level: .fine),
        StringProperty('Version', info.appVersion, level: .fine),
        StringProperty('Build Number', info.productSub, level: .fine),
      ],
    ),
    StringProperty('Language', info.language),
    IterableProperty('Languages', info.languages),
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
        (deviceMemory * 1024 * 1024 * 1024).round().formatByteSize(
          prefix: Prefix.binary,
        ),
      ),
  ];
}
