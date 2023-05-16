import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../debug_helper.dart';

class MediaQueryDebugHelper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DiagnosticsBasedDebugHelper(
      title: const Text('MediaQuery'),
      // ignore: discarded_futures, https://github.com/dart-lang/linter/issues/3429
      diagnosticsStream: _getDiagnostics(context).asStream(),
    );
  }

  Future<List<DiagnosticsNode>> _getDiagnostics(BuildContext context) async {
    var data = MediaQuery.maybeOf(context);
    if (data == null) {
      data = MediaQueryData.fromView(View.of(context));
      if (!kReleaseMode) {
        data = data.copyWith(platformBrightness: debugBrightnessOverride);
      }
    }

    return [
      DiagnosticsProperty('Size', data.size, defaultValue: Size.zero),
      DoubleProperty(
        'Device Pixel Ratio',
        data.devicePixelRatio,
        defaultValue: 1,
      ),
      DoubleProperty(
        'Text Scale Factor',
        data.textScaleFactor,
        defaultValue: 1,
      ),
      EnumProperty('Platform Brightness', data.platformBrightness),
      DiagnosticsProperty(
        'Padding',
        data.padding,
        defaultValue: EdgeInsets.zero,
      ),
      DiagnosticsProperty(
        'View Insets',
        data.viewInsets,
        defaultValue: EdgeInsets.zero,
      ),
      DiagnosticsProperty(
        'System Gesture Insets',
        data.systemGestureInsets,
        defaultValue: EdgeInsets.zero,
      ),
      DiagnosticsProperty(
        'View Padding',
        data.viewPadding,
        defaultValue: EdgeInsets.zero,
      ),
      FlagProperty(
        'Always use 24 Hour Format',
        value: data.alwaysUse24HourFormat,
        ifTrue: 'Always use 24 Hour Format',
      ),
      FlagProperty(
        'Accessible Navigation',
        value: data.accessibleNavigation,
        ifTrue: 'Use accessible navigation',
      ),
      FlagProperty(
        'Invert Colors',
        value: data.invertColors,
        ifTrue: 'The device inverts colors',
      ),
      FlagProperty(
        'High Contrast',
        value: data.highContrast,
        ifTrue: 'Should use high contrast',
      ),
      FlagProperty(
        'Disable Animations',
        value: data.disableAnimations,
        ifTrue: 'Disable animations',
      ),
      FlagProperty(
        'Bold Text',
        value: data.boldText,
        ifTrue: 'Use bold text',
      ),
      EnumProperty(
        'Navigation Mode',
        data.navigationMode,
        defaultValue: NavigationMode.traditional,
      ),
    ];
  }
}
