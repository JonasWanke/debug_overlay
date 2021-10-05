import 'dart:ui';

import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/cupertino.dart';
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
    MediaQueryDebugHelper(),
    PackageInfoDebugHelper(),
    DeviceInfoDebugHelper(),
  ]);

  static void prependHelper(Widget debugHelper) {
    helpers.value = [debugHelper, ...helpers.value];
  }

  static void appendHelper(Widget debugHelper) {
    helpers.value = [...helpers.value, debugHelper];
  }

  /// In debug mode, this returns a builder to add a [DebugOverlay] to your app.
  ///
  /// In profile and release builds, the returned builder doesn't add any
  /// widgets.
  ///
  /// This is usually used as the [WidgetsApp.builder]/[MaterialApp.builder]/
  /// [CupertinoApp.builder]:
  ///
  /// ```dart
  /// MaterialApp(
  ///   title: 'My Fancy App',
  ///   builder: DebugOverlay.builder(),
  ///   home: MyHomePage(),
  /// )
  /// ```
  ///
  /// You can open the overlay by shaking your phone (if [showOnShake] is
  /// `true`) or by calling [show] or [hide].
  static TransitionBuilder builder({bool showOnShake = true}) {
    // ignore: omit_local_variable_types
    TransitionBuilder builder = (context, child) => child ?? SizedBox();
    assert(() {
      builder = (context, child) {
        return DebugOverlay(child: child, showOnShake: showOnShake);
      };
      return true;
    }());
    return builder;
  }

  static void show() => DebugOverlayState.key.currentState!.show();
  static void hide() => DebugOverlayState.key.currentState!.hide();

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
    return Stack(children: [
      if (widget.child != null) widget.child!,
      if (bottomSheet != null) Positioned.fill(child: bottomSheet!),
    ]);
  }

  double _extent = 0;
  Widget _buildBottomSheet() {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        setState(() => _extent = notification.extent);
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.4,
        builder: (context, scrollController) {
          final drawer = Material(
            elevation: 16,
            child: DebugOverlayContent(
              scrollController: scrollController,
              onClose: hide,
            ),
          );

          final navigator = Navigator(
            // We need a [Navigator] for inner overlays.
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => _ScaledTopViewPadding(
                progress:
                    Interval(0.7, 1, curve: Curves.easeIn).transform(_extent),
                child: drawer,
              ),
            ),
          );
          return HeroControllerScope.none(child: navigator);
        },
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
    return Scaffold(
      body: ValueListenableBuilder<List<Widget>>(
        valueListenable: DebugOverlay.helpers,
        builder: (context, helpers, _) => ListView.separated(
          primary: false,
          controller: scrollController,
          padding: context.mediaQuery.viewPadding + EdgeInsets.only(bottom: 16),
          itemCount: helpers.length + 1,
          itemBuilder: (context, index) =>
              index == 0 ? _buildAppBar(context) : helpers[index - 1],
          separatorBuilder: (context, index) =>
              SizedBox(height: index == 0 ? 0 : 16),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
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

class _ScaledTopViewPadding extends StatelessWidget {
  const _ScaledTopViewPadding({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = context.mediaQuery;
    return MediaQuery(
      data: data.copyWith(
        viewPadding: data.viewPadding
            .copyWith(top: lerpDouble(0, data.viewPadding.top, progress)!),
      ),
      child: child,
    );
  }
}
