import 'dart:ui';

import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'debug_overlay_bubble.dart';
import 'debug_overlay_trigger.dart';
import 'debug_tool.dart';
import 'helpers/media_query.dart';
import 'helpers/rendering.dart';

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

  /// Static so that it survives the overlay being remounted, e.g., when the
  /// app wraps its content in an additional widget (like the performance
  /// overlay does).
  static final _selectedToolIndex = ValueNotifier(0);

  static void close() => mode.value = .closed;
  static void collapse() => mode.value = .collapsed;
  static void expand() => mode.value = .expanded;

  static final tools = ValueNotifier<List<DebugTool>>([
    // Only works in debug mode; see the documentation of
    // [DiagnosticsBasedDebugHelper] for the explanation.
    if (kDebugMode) MediaQueryDebugHelper.tool,
    RenderingDebugHelper.tool,
  ]);

  static void prependTool(DebugTool tool) {
    tools.value = [tool, ...tools.value];
  }

  static void appendTool(DebugTool tool) {
    tools.value = [...tools.value, tool];
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
              Positioned.fill(
                child: _ExpandedSheet(
                  selectedToolIndex: DebugOverlay._selectedToolIndex,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class const _ExpandedSheet({
  required final ValueNotifier<int> selectedToolIndex,
}) extends StatefulWidget {
  @override
  State<_ExpandedSheet> createState() => _ExpandedSheetState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('selectedToolIndex', selectedToolIndex));
  }
}

class _ExpandedSheetState extends State<_ExpandedSheet> {
  // Notifier instead of [setState] because the [Navigator] below only builds
  // its route once, so its content has to listen itself.
  final _extent = ValueNotifier<double>(0);

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        _extent.value = notification.extent;

        // Dragging (or flinging) the sheet down to its minimum size collapses
        // it into the bubble.
        if (notification.extent <= notification.minExtent) {
          DebugOverlay.collapse();
        }
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.15,
        builder: (context, scrollController) {
          final drawer = Material(
            elevation: 16,
            child: ValueListenableBuilder(
              valueListenable: widget.selectedToolIndex,
              builder: (context, selectedToolIndex, _) => DebugOverlayContent(
                scrollController: scrollController,
                selectedToolIndex: selectedToolIndex,
                onSelectedToolIndexChanged: (it) =>
                    widget.selectedToolIndex.value = it,
                onCollapse: DebugOverlay.collapse,
              ),
            ),
          );

          final navigator = Navigator(
            // We need a [Navigator] for inner overlays.
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => ValueListenableBuilder(
                valueListenable: _extent,
                builder: (context, extent, _) => _ScaledTopViewPadding(
                  progress: const Interval(
                    0.7,
                    1,
                    curve: Curves.easeIn,
                  ).transform(extent),
                  child: drawer,
                ),
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
  final int selectedToolIndex = 0,
  final ValueChanged<int>? onSelectedToolIndexChanged,
  final VoidCallback? onCollapse,
}) extends StatefulWidget {
  @override
  State<DebugOverlayContent> createState() => _DebugOverlayContentState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('scrollController', scrollController))
      ..add(IntProperty('selectedToolIndex', selectedToolIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>?>.has(
          'onSelectedToolIndexChanged',
          onSelectedToolIndexChanged,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback?>.has('onCollapse', onCollapse));
  }
}

class _DebugOverlayContentState extends State<DebugOverlayContent> {
  /// The scroll offset of each tool when it was last deselected.
  final _scrollOffsets = <DebugTool, double>{};

  @override
  Widget build(BuildContext context) {
    final viewPadding = context.mediaQuery.viewPadding;
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: DebugOverlay.tools,
        builder: (context, tools, _) {
          final selectedIndex = tools.isEmpty
              ? null
              : widget.selectedToolIndex.clamp(0, tools.length - 1);
          return CustomScrollView(
            primary: false,
            controller: widget.scrollController,
            slivers: [
              SliverPinnedHeader(
                child: _buildHeader(context, tools, selectedIndex),
              ),
              if (selectedIndex == null)
                const SliverToBoxAdapter(
                  child: Center(child: Text('No debug tools registered')),
                )
              else
                SliverPadding(
                  padding: .fromLTRB(
                    viewPadding.left,
                    8,
                    viewPadding.right,
                    viewPadding.bottom + 16,
                  ),
                  sliver: tools[selectedIndex].sliver,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<DebugTool> tools,
    int? selectedIndex,
  ) {
    final viewPadding = context.mediaQuery.viewPadding;
    // Sliver content is painted over the header's shadow, so we use a
    // different background color and a divider to separate it from the
    // content below.
    return Material(
      color: context.theme.colorScheme.surfaceContainerHigh,
      child: Column(
        mainAxisSize: .min,
        children: [
          Padding(
            padding: .fromLTRB(
              viewPadding.left + 8,
              viewPadding.top + 4,
              viewPadding.right + 8,
              4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: .horizontal,
                    child: Row(
                      children: [
                        for (final (index, tool) in tools.indexed)
                          (index == selectedIndex
                              ? IconButton.filledTonal
                              : IconButton.new)(
                            icon: Icon(tool.icon),
                            tooltip: tool.title,
                            onPressed: () =>
                                _select(tools, selectedIndex!, index),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.onCollapse != null)
                  IconButton(
                    icon: const Icon(Icons.close_fullscreen),
                    tooltip: 'Collapse',
                    onPressed: widget.onCollapse,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  void _select(List<DebugTool> tools, int oldIndex, int newIndex) {
    if (newIndex == oldIndex) return;

    final controller = widget.scrollController;
    if (controller != null && controller.hasClients) {
      _scrollOffsets[tools[oldIndex]] = controller.offset;
    }
    widget.onSelectedToolIndexChanged?.call(newIndex);

    // The new tool's content is only laid out in the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || controller == null || !controller.hasClients) return;

      final offset = _scrollOffsets[tools[newIndex]] ?? 0;
      controller.jumpTo(offset.clamp(0, controller.position.maxScrollExtent));
    });
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
