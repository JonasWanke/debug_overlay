import 'dart:async';

import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../debug_tool.dart';

/// A [DebugTool] with switches for Flutter's debug rendering flags (e.g.,
/// [debugPaintSizeEnabled]), a slider for [timeDilation], and a switch for the
/// performance overlay, and controls for the system UI (status and navigation
/// bar visibility and [SystemUiMode]).
///
/// The debug flags only have an effect in debug mode. In other modes, the
/// corresponding controls are disabled. The performance overlay is also
/// unavailable on the web, and the system UI controls only work on Android and
/// iOS.
///
/// Changing a flag reassembles the whole application (see
/// [BindingBase.reassembleApplication]), so that already painted frames pick
/// up the change. This preserves state, but is expensive.
class RenderingDebugTool() extends DebugTool {
  this : super(icon: Icons.brush, title: 'Rendering');

  // The platform offers no way to read the current system UI state, so we track
  // what we set. `null` means that we haven't changed anything yet.
  SystemUiMode? _systemUiMode;
  Set<SystemUiOverlay> _systemUiOverlays = {...SystemUiOverlay.values};

  @override
  Widget buildSliver(BuildContext context) {
    final isSystemUiSupported =
        !kIsWeb &&
        (defaultTargetPlatform == .android || defaultTargetPlatform == .iOS);
    final systemUiMode = MenuAnchor(
      menuChildren: [
        for (final mode in SystemUiMode.values)
          if (mode != SystemUiMode.manual)
            MenuItemButton(
              onPressed: () => _setSystemUiMode(mode),
              trailingIcon: mode == _systemUiMode
                  ? const Icon(Icons.check)
                  : null,
              child: Text(mode.name),
            ),
      ],
      builder: (context, controller, _) => ListTile(
        enabled: isSystemUiSupported,
        title: const Text('System UI Mode'),
        subtitle: Text(_systemUiMode?.name ?? 'Not changed'),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: controller.toggle,
      ),
    );

    return SliverList.list(
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
        ListTile(
          title: const Text('System UI'),
          subtitle: isSystemUiSupported
              ? null
              : const Text('Only supported on Android and iOS'),
        ),
        for (final overlay in SystemUiOverlay.values)
          SwitchListTile(
            title: Text(switch (overlay) {
              .top => 'Status Bar',
              .bottom => 'Navigation Bar',
            }),
            subtitle: Text('SystemUiOverlay.${overlay.name}'),
            value: _systemUiOverlays.contains(overlay),
            onChanged: isSystemUiSupported
                ? (it) => _setSystemUiOverlay(overlay, isVisible: it)
                : null,
          ),
        systemUiMode,
      ],
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
        onChanged: (it) {
          timeDilation = it;
          notifyListeners();
        },
      ),
    );
  }

  void _setSystemUiOverlay(SystemUiOverlay overlay, {required bool isVisible}) {
    _systemUiOverlays = {
      for (final it in SystemUiOverlay.values)
        if (it == overlay ? isVisible : _systemUiOverlays.contains(it)) it,
    };
    _systemUiMode = .manual;
    notifyListeners();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: _systemUiOverlays.toList(),
      ),
    );
  }

  void _setSystemUiMode(SystemUiMode mode) {
    _systemUiMode = mode;
    _systemUiOverlays = {...SystemUiOverlay.values};
    notifyListeners();
    unawaited(SystemChrome.setEnabledSystemUIMode(mode));
  }

  void _update(VoidCallback change) {
    change();
    notifyListeners();
    unawaited(WidgetsBinding.instance.reassembleApplication());
  }
}
