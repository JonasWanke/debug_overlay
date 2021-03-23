import 'package:flutter/material.dart';
import 'package:shake/shake.dart';
import 'package:black_hole_flutter/black_hole_flutter.dart';

import 'helpers/device_info.dart';
import 'helpers/media_query.dart';
import 'helpers/package_info.dart';

class DebugOverlay extends StatefulWidget {
  DebugOverlay({
    required this.child,
    this.showOnShake = true,
    this.enableOpenDragGesture = false,
  }) : super(key: DebugOverlayState.key);

  static final helpers = ValueNotifier<List<Widget>>([
    DeviceInfoDebugHelper(),
    PackageInfoDebugHelper(),
    MediaQueryDebugHelper(),
  ]);

  static void addHelper(Widget debugHelper) {
    helpers.value = [...helpers.value, debugHelper];
  }

  static TransitionBuilder builder({
    bool showOnShake = true,
    bool enableOpenDragGesture = false,
  }) {
    return (context, child) {
      return DebugOverlay(
        child: child,
        showOnShake: showOnShake,
        enableOpenDragGesture: enableOpenDragGesture,
      );
    };
  }

  static void show() => DebugOverlayState.key.currentState!.show();

  final Widget? child;

  final bool showOnShake;
  final bool enableOpenDragGesture;

  @override
  DebugOverlayState createState() => DebugOverlayState();
}

class DebugOverlayState extends State<DebugOverlay> {
  static final key = GlobalKey<DebugOverlayState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  ShakeDetector? _shakeDetector;

  @override
  void initState() {
    super.initState();
    if (widget.showOnShake) _configureShakeDetector();
  }

  @override
  void didUpdateWidget(DebugOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.showOnShake && widget.showOnShake) {
      _configureShakeDetector();
    } else if (oldWidget.showOnShake && !widget.showOnShake) {
      _shakeDetector?.stopListening();
      _shakeDetector = null;
    }
  }

  void _configureShakeDetector() {
    assert(widget.showOnShake);
    assert(_shakeDetector == null);

    _shakeDetector = ShakeDetector.autoStart(onPhoneShake: () {
      show();
    });
  }

  @override
  void dispose() {
    _shakeDetector?.stopListening();
    super.dispose();
  }

  void show() => _scaffoldKey.currentState!.openEndDrawer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: widget.child,
      endDrawer: Drawer(
        child: HeroControllerScope.none(
          child: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => DebugOverlayContent(),
            ),
          ),
        ),
      ),
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
