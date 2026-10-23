import 'dart:ui';

import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'debug_overlay_bubble.dart';
import 'debug_overlay_trigger.dart';
import 'helpers/device_info.dart';
import 'helpers/media_query.dart';
import 'helpers/package_info.dart';

/// How much of the [DebugOverlay] is visible.
enum DebugOverlayMode {
  /// Nothing is visible.
  ///
  /// The user can still open the overlay via the [DebugOverlayTrigger].
  closed,

  /// Only a draggable bubble is visible.
  ///
  /// Tapping it expands the overlay; dropping it onto the dismiss target closes
  /// the overlay.
  collapsed,

  /// The sheet with all debug helpers is visible.
  expanded,
}

class const DebugOverlay({
  super.key,
  required final Widget? child,
  final DebugOverlayTrigger trigger = const DebugOverlayTrigger(),
  final bool enableOnlyInDebugMode = true,
}) extends StatefulWidget {
  /// The current mode of the overlay.
  ///
  /// Starts as [DebugOverlayMode.closed]; set it before `runApp` to start in a
  /// different mode. Has no visible effect if the overlay is disabled (see
  /// [enableOnlyInDebugMode]).
  static final mode = ValueNotifier(DebugOverlayMode.closed);

  static void close() => mode.value = .closed;
  static void collapse() => mode.value = .collapsed;
  static void expand() => mode.value = .expanded;

  static final helpers = ValueNotifier<List<Widget>>([
    if (kDebugMode) ...[
      // These only work in debug mode; see the documentation of
      // [DiagnosticsBasedDebugHelper] for the explanation.
      const MediaQueryDebugHelper(),
      const PackageInfoDebugHelper(),
      const DeviceInfoDebugHelper(),
    ],
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
  /// widgets unless [enableOnlyInDebugMode] is set to `false`.
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
  /// The user can open the overlay using the [trigger]. You can also control
  /// it via [mode], [close], [collapse], and [expand].
  static TransitionBuilder builder({
    DebugOverlayTrigger trigger = const DebugOverlayTrigger(),
    bool enableOnlyInDebugMode = true,
  }) {
    return kDebugMode || !enableOnlyInDebugMode
        ? (context, child) => DebugOverlay(
            trigger: trigger,
            enableOnlyInDebugMode: enableOnlyInDebugMode,
            child: child,
          )
        : (context, child) => child ?? const SizedBox();
  }

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('trigger', trigger))
      ..add(
        FlagProperty(
          'enableOnlyInDebugMode',
          value: enableOnlyInDebugMode,
          ifTrue: 'enabled only in debug mode',
        ),
      );
  }
}

class _DebugOverlayState extends State<DebugOverlay> {
  var _bubbleAlignment = const Alignment(1, -0.4);

  @override
  Widget build(BuildContext context) {
    if (!(kDebugMode || !widget.enableOnlyInDebugMode)) {
      return widget.child ?? const SizedBox();
    }

    return DebugOverlayTriggerDetector(
      trigger: widget.trigger,
      onTriggered: DebugOverlay.expand,
      child: ValueListenableBuilder(
        valueListenable: DebugOverlay.mode,
        builder: (context, mode, _) => Stack(
          children: [
            ?widget.child,
            if (mode == .collapsed)
              Positioned.fill(
                child: DebugOverlayBubble(
                  alignment: _bubbleAlignment,
                  onAlignmentChanged: (it) =>
                      setState(() => _bubbleAlignment = it),
                ),
              ),
            if (mode == .expanded)
              const Positioned.fill(child: _ExpandedSheet()),
          ],
        ),
      ),
    );
  }
}

class const _ExpandedSheet() extends StatefulWidget {
  @override
  State<_ExpandedSheet> createState() => _ExpandedSheetState();
}

class _ExpandedSheetState extends State<_ExpandedSheet> {
  double _extent = 0;

  @override
  Widget build(BuildContext context) {
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
              onCollapse: DebugOverlay.collapse,
            ),
          );

          final navigator = Navigator(
            // We need a [Navigator] for inner overlays.
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => _ScaledTopViewPadding(
                progress: const Interval(
                  0.7,
                  1,
                  curve: Curves.easeIn,
                ).transform(_extent),
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

class const DebugOverlayContent({
  super.key,
  final ScrollController? scrollController,
  final VoidCallback? onCollapse,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      primary: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor:
          context.theme.scaffoldBackgroundColor.highEmphasisOnColor,
      title: const Text('🐛 Debug Overlay'),
      actions: [
        if (onCollapse != null)
          IconButton(
            icon: const Icon(Icons.close_fullscreen),
            tooltip: 'Collapse',
            onPressed: onCollapse,
          ),
      ],
    );

    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: DebugOverlay.helpers,
        builder: (context, helpers, _) => CustomScrollView(
          primary: false,
          controller: scrollController,
          slivers: [
            SliverPadding(
              padding:
                  context.mediaQuery.viewPadding +
                  const EdgeInsets.only(bottom: 16),
              sliver: MultiSliver(
                children: [
                  SliverToBoxAdapter(child: appBar),
                  ...helpers.withSeparators(const SizedBox(height: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('scrollController', scrollController))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onCollapse', onCollapse));
  }
}

class const _ScaledTopViewPadding({
  required final double progress,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = context.mediaQuery;
    return MediaQuery(
      data: data.copyWith(
        viewPadding: data.viewPadding.copyWith(
          top: lerpDouble(0, data.viewPadding.top, progress)!,
        ),
      ),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('progress', progress));
  }
}

extension<T> on Iterable<T> {
  Iterable<T> withSeparators(T separator) sync* {
    var isFirst = true;
    for (final item in this) {
      if (!isFirst) yield separator;
      isFirst = false;

      yield item;
    }
  }
}
