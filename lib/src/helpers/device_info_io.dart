import 'dart:io';

import 'package:data_size/data_size.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_info_plus_platform_interface/device_info_plus_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supercharged/supercharged.dart';

Future<List<DiagnosticsNode>> getDiagnostics() async {
  assert(!kIsWeb);

  if (Platform.isAndroid) return _getDiagnosticsAndroid();
  if (Platform.isIOS) return _getDiagnosticsIos();
  if (Platform.isWindows) return _getDiagnosticsWindows();
  if (Platform.isLinux) return _getDiagnosticsLinux();
  if (Platform.isMacOS) return _getDiagnosticsMacOs();
  if (Platform.isFuchsia) return [StringProperty('OS', 'Fuchsia')];
  return [StringProperty('OS', 'unknown')];
}

Future<List<DiagnosticsNode>> _getDiagnosticsAndroid() async {
  AndroidDeviceInfo info;
  try {
    info = await DeviceInfoPlugin().androidInfo;
  } catch (_) {
    // Workaround for https://github.com/fluttercommunity/plus_plugins/issues/184
    return [StringProperty('OS', 'Android')];
  }
  return [
    DiagnosticsBlock(
      name: 'OS: Android',
      properties: [
        // StringProperty('Name', info.systemName),
        // StringProperty('Version', info.systemVersion),
        StringProperty('Build Type', info.type),
        StringProperty('Build Tags', info.tags),
        StringProperty(
          'Fingerprint',
          info.fingerprint,
          level: DiagnosticLevel.fine,
        ),
        StringProperty(
          'Android ID',
          info.androidId,
          level: DiagnosticLevel.fine,
        ),
        FlagsSummary(
          'Supported 32-Bit ABIs',
          info.supported32BitAbis.associateWith((it) => true),
        ),
        FlagsSummary(
          'Supported 64-Bit ABIs',
          info.supported64BitAbis.associateWith((it) => true),
        ),
        FlagsSummary(
          'Supported ABIs',
          info.supportedAbis.associateWith((it) => true),
        ),
        FlagsSummary(
          'System Features',
          info.systemFeatures.associateWith((it) => true),
          level: DiagnosticLevel.fine,
        ),
      ],
      children: [
        // StringProperty('Version', info.version),
        DiagnosticsBlock(
          name: 'Version',
          properties: [
            StringProperty('Version', info.version.release),
            IntProperty('SDK Version', info.version.sdkInt, defaultValue: -1),
            IntProperty(
              'Developer Preview SDK',
              info.version.previewSdkInt,
              defaultValue: 0,
            ),
            StringProperty(
              'Base OS Build',
              info.version.baseOS,
              defaultValue: '',
            ),
            StringProperty(
              'Security Patch',
              info.version.securityPatch,
              defaultValue: '',
            ),
            StringProperty(
              'Codename',
              info.version.codename,
              defaultValue: 'REL',
            ),
            StringProperty('Incremental', info.version.incremental),
          ],
        ),
      ],
    ),
    DiagnosticsBlock(
      name: 'Device',
      properties: [
        FlagProperty(
          'Is a physical device?',
          value: info.isPhysicalDevice,
          ifTrue: 'Running on a physical device',
          ifFalse: 'Running on an emulator or unknown device',
        ),
        StringProperty(
          'Board',
          info.board,
          level: DiagnosticLevel.fine,
        ),
        StringProperty('Manufacturer', info.manufacturer),
        StringProperty('Brand', info.brand),
        StringProperty('Product', info.product),
        StringProperty('Device', info.device),
        StringProperty('Model', info.model),
        StringProperty(
          'Display',
          info.display,
          level: DiagnosticLevel.fine,
        ),
        StringProperty('Bootloader', info.bootloader),
        StringProperty('Hardware', info.hardware),
        StringProperty('Hostname', info.host),
        StringProperty('Changelist Number / Label', info.id),
      ],
    ),
  ];
}

Future<List<DiagnosticsNode>> _getDiagnosticsIos() async {
  final info = await DeviceInfoPlugin().iosInfo;
  return [
    DiagnosticsBlock(
      name: 'OS: iOS',
      properties: [
        StringProperty('Name', info.systemName),
        StringProperty('Version', info.systemVersion),
      ],
      children: [
        DiagnosticsBlock(
          name: 'utsname',
          properties: [
            StringProperty('Name', info.utsname.sysname),
            StringProperty('Network Node Name', info.utsname.nodename),
            StringProperty('Release Level', info.utsname.release),
            StringProperty('Version Level', info.utsname.version),
            StringProperty('Hardware Type', info.utsname.machine),
          ],
        ),
      ],
    ),
    DiagnosticsBlock(
      name: 'Device',
      properties: [
        FlagProperty(
          'Is a physical device?',
          value: info.isPhysicalDevice,
          ifTrue: 'Running on a physical device',
          ifFalse: 'Running on a simulator or unknown device',
        ),
        StringProperty('Name', info.name),
        StringProperty('Model', info.model),
        StringProperty('Model (localized)', info.localizedModel),
        StringProperty(
          'Identifier for the Vendor',
          info.identifierForVendor,
          level: DiagnosticLevel.fine,
        ),
      ],
    ),
  ];
}

Future<List<DiagnosticsNode>> _getDiagnosticsWindows() async {
  final info = await DeviceInfoPlugin().windowsInfo;
  return [
    StringProperty('OS', 'Windows'),
    StringProperty('Computer Name', info.computerName, defaultValue: ''),
    IntProperty('Core Count', info.numberOfCores),
    // The getter says megabytes, but it's actually mebibytes…
    StringProperty(
      'Memory Size',
      (info.systemMemoryInMegabytes * 1024 * 1024)
          .formatByteSize(prefix: Prefix.binary),
    ),
  ];
}

Future<List<DiagnosticsNode>> _getDiagnosticsLinux() async {
  final info = await DeviceInfoPlugin().linuxInfo;
  return [
    StringProperty('OS', info.prettyName),
    StringProperty(
      'ID',
      info.id,
      defaultValue: 'linux',
      level: DiagnosticLevel.fine,
    ),
    IterableProperty('ID-like', info.idLike),
    StringProperty('Version', info.version, defaultValue: null),
    StringProperty('Version ID', info.versionId, defaultValue: null),
    StringProperty(
      'Version Codename',
      info.versionCodename,
      defaultValue: null,
    ),
    StringProperty('Build ID', info.buildId, defaultValue: null),
    StringProperty('Variant', info.variant, defaultValue: null),
    StringProperty(
      'Variant ID',
      info.variantId,
      defaultValue: null,
      level: DiagnosticLevel.fine,
    ),
    StringProperty(
      'Machine ID',
      info.machineId,
      defaultValue: null,
      level: DiagnosticLevel.fine,
    ),
  ];
}

Future<List<DiagnosticsNode>> _getDiagnosticsMacOs() async {
  final info = await DeviceInfoPlugin().macOsInfo;
  return [
    StringProperty('OS', 'macOS'),
    StringProperty('OS Release', info.osRelease),
    StringProperty(
      'Kernel Version',
      info.kernelVersion,
      level: DiagnosticLevel.fine,
    ),
    StringProperty('Architecture', info.arch),
    StringProperty('Device Model', info.model),
    StringProperty('Computer Name', info.computerName),
    StringProperty('Host Name', info.hostName),
    IntProperty('Active CPUs', info.activeCPUs),
    StringProperty(
      'Memory Size',
      info.memorySize.formatByteSize(prefix: Prefix.binary),
    ),
    StringProperty(
      'CPU Frequency',
      '${Prefix.decimal.format(info.cpuFrequency)}Hz',
    ),
  ];
}
