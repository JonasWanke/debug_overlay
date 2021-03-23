import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shake/shake.dart';

import 'helpers/device_info.dart';
import 'helpers/media_query.dart';
import 'helpers/package_info.dart';

class DebugOverlay extends StatefulWidget {
  DebugOverlay({
    required this.child,
    this.showOnShake = true,
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
  }) {
    return (context, child) {
      return DebugOverlay(child: child, showOnShake: showOnShake);
    };
  }

  static void show() => DebugOverlayState.key.currentState!.show();

  final Widget? child;

  final bool showOnShake;

  @override
  DebugOverlayState createState() => DebugOverlayState();
}

class DebugOverlayState extends State<DebugOverlay> {
  static final key = GlobalKey<DebugOverlayState>();

  ShakeDetector? _shakeDetector;
  bool _isVisible = false;

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

  void show() => setState(() => _isVisible = true);
  void hide() => setState(() => _isVisible = false);

  @override
  Widget build(BuildContext context) {
    Widget? bottomSheet;
    assert(() {
      if (!_isVisible) return true;
      bottomSheet = _buildBottomSheet();
      return true;
    }());
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        if (bottomSheet != null) Positioned.fill(child: bottomSheet!),
      ],
    );
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      builder: (context, scrollController) => HeroControllerScope.none(
        child: Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => Drawer(
              elevation: 16,
              child: DebugOverlayContent(
                scrollController: scrollController,
                onClose: hide,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DebugOverlayContent extends StatelessWidget {
  const DebugOverlayContent({this.scrollController, this.onClose});

  final ScrollController? scrollController;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Widget>>(
      valueListenable: DebugOverlay.helpers,
      builder: (context, helpers, _) => ListView.separated(
        primary: false,
        controller: scrollController,
        padding: EdgeInsets.only(bottom: 0),
        itemCount: helpers.length + 1,
        itemBuilder: (context, index) =>
            index == 0 ? _buildAppBar(context) : helpers[index - 1],
        separatorBuilder: (context, index) =>
            SizedBox(height: index == 0 ? 0 : 16),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      backwardsCompatibility: false,
      primary: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor:
          context.theme.scaffoldBackgroundColor.highEmphasisOnColor,
      title: Text('🐛 Debug Overlay'),
      actions: [if (onClose != null) CloseButton(onPressed: onClose!)],
    );
  }
}
