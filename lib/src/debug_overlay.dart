import 'package:flutter/material.dart';
import 'package:shake/shake.dart';
import 'package:black_hole_flutter/black_hole_flutter.dart';

import 'helpers/device_info.dart';
import 'helpers/media_query.dart';
import 'helpers/package_info.dart';

class DebugOverlay extends StatefulWidget {
  const DebugOverlay({
    required this.child,
    this.showOnShake = true,
    this.enableOpenDragGesture = false,
  });

  final Widget? child;

  final bool showOnShake;
  final bool enableOpenDragGesture;

  static final helpers = ValueNotifier<List<Widget>>([
    DeviceInfoDebugHelper(),
    PackageInfoDebugHelper(),
    MediaQueryDebugHelper(),
  ]);

  static void addHelper(Widget debugHelper) {
    helpers.value = [...helpers.value, debugHelper];
  }

  static TransitionBuilder get builder {
    return (context, child) {
      return DebugOverlay(child: child);
    };
  }

  @override
  DebugOverlayState createState() => DebugOverlayState();
}

class DebugOverlayState extends State<DebugOverlay> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late final ShakeDetector? _shakeDetector;

  @override
  void initState() {
    super.initState();
    if (widget.showOnShake) {
      _shakeDetector = ShakeDetector.autoStart(onPhoneShake: () {
        _scaffoldKey.currentState!.openEndDrawer();
      });
    }
  }

  @override
  void dispose() {
    _shakeDetector?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: widget.child,
      endDrawer: Drawer(child: DebugOverlayContent()),
      endDrawerEnableOpenDragGesture: widget.enableOpenDragGesture,
    );
  }
}

class DebugOverlayContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Widget>>(
      valueListenable: DebugOverlay.helpers,
      builder: (context, helpers, _) => ListView.separated(
        padding: context.mediaQuery.viewPadding + EdgeInsets.all(16),
        itemCount: helpers.length,
        itemBuilder: (context, index) => helpers[index],
        separatorBuilder: (context, index) => SizedBox(height: 16),
      ),
    );
  }
}
