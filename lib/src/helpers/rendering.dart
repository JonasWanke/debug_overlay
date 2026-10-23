import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../debug_helper.dart';
import '../debug_tool.dart';

/// Switches for Flutter's debug rendering flags (e.g.,
/// [debugPaintSizeEnabled]), a slider for [timeDilation], and a switch for the
/// performance overlay.
///
/// The debug flags only have an effect in debug mode. In other modes, the
/// corresponding controls are disabled. The performance overlay is also
/// unavailable on the web.
///
/// Changing a flag reassembles the whole application (see
/// [BindingBase.reassembleApplication]), so that already painted frames pick
/// up the change. This preserves state, but is expensive.
class const RenderingDebugHelper({super.key}) extends StatefulWidget {
  static const tool = DebugTool(
    icon: Icons.brush,
    title: 'Rendering',
    sliver: RenderingDebugHelper(),
  );

  @override
  State<RenderingDebugHelper> createState() => _RenderingDebugHelperState();
}

class _RenderingDebugHelperState extends State<RenderingDebugHelper> {
  @override
  Widget build(BuildContext context) {
    return DebugHelper(
      contentPadding: EdgeInsets.zero,
      sliver: SliverList.list(
        children: [
          if (!kDebugMode)
            const ListTile(
              title: Text('Most options are only available in debug mode.'),
            ),
          _buildFlag(
            title: 'Paint Sizes',
            subtitle: 'debugPaintSizeEnabled',
            value: debugPaintSizeEnabled,
            onChanged: (it) => debugPaintSizeEnabled = it,
          ),
          _buildFlag(
            title: 'Paint Baselines',
            subtitle: 'debugPaintBaselinesEnabled',
            value: debugPaintBaselinesEnabled,
            onChanged: (it) => debugPaintBaselinesEnabled = it,
          ),
          _buildFlag(
            title: 'Paint Pointers',
            subtitle: 'debugPaintPointersEnabled',
            value: debugPaintPointersEnabled,
            onChanged: (it) => debugPaintPointersEnabled = it,
          ),
          _buildFlag(
            title: 'Repaint Rainbow',
            subtitle: 'debugRepaintRainbowEnabled',
            value: debugRepaintRainbowEnabled,
            onChanged: (it) => debugRepaintRainbowEnabled = it,
          ),
          _buildPerformanceOverlay(),
          _buildTimeDilation(),
        ],
      ),
    );
  }

  Widget _buildFlag({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: kDebugMode ? (it) => _update(() => onChanged(it)) : null,
    );
  }

  Widget _buildPerformanceOverlay() {
    return SwitchListTile(
      title: const Text('Performance Overlay'),
      subtitle: const Text('Not supported on the web'),
      value: WidgetsApp.showPerformanceOverlayOverride,
      onChanged: kIsWeb
          ? null
          : (it) {
              _update(() => WidgetsApp.showPerformanceOverlayOverride = it);
            },
    );
  }

  Widget _buildTimeDilation() {
    return ListTile(
      title: Text('Time Dilation: ${timeDilation.toStringAsFixed(1)}x'),
      subtitle: Slider(
        value: timeDilation.clamp(1, 20),
        min: 1,
        max: 20,
        divisions: 19,
        label: '${timeDilation.toStringAsFixed(1)}x',
        // Animations pick up the new value on the next frame, so no reassemble
        // is necessary.
        onChanged: (it) => setState(() => timeDilation = it),
      ),
    );
  }

  void _update(VoidCallback change) {
    setState(change);
    unawaited(WidgetsBinding.instance.reassembleApplication());
  }
}
