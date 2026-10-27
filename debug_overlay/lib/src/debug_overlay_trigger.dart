import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'debug_overlay.dart';

/// Configures how the user can open the [DebugOverlay] without code.
///
/// Both triggers expand the overlay. Use [none] if you want to control the
/// overlay only via [DebugOverlay.mode] and the functions next to it.
class const DebugOverlayTrigger({
  /// Whether pressing and holding two fingers on the screen expands the
  /// overlay.
  ///
  /// The hold is cancelled if a finger moves, so pinch and pan gestures of
  /// your app are not affected.
  final bool twoFingerHold = true,

  /// How long two fingers have to be held down to trigger the overlay.
  final Duration holdDuration = kLongPressTimeout,

  /// A keyboard shortcut that expands the overlay, mainly for platforms
  /// without a touch screen.
  final ShortcutActivator? keyboardShortcut = const SingleActivator(
    .f12,
    alt: true,
  ),
}) {
  static const none = DebugOverlayTrigger(
    twoFingerHold: false,
    keyboardShortcut: null,
  );
}

/// Detects [DebugOverlayTrigger]s.
///
/// This uses raw pointer events instead of a gesture recognizer, so it never
/// enters the gesture arena and can't steal gestures from [child].
@internal
class const DebugOverlayTriggerDetector({
  super.key,
  required final DebugOverlayTrigger trigger,
  required final VoidCallback onTriggered,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<DebugOverlayTriggerDetector> createState() =>
      _DebugOverlayTriggerDetectorState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('trigger', trigger))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTriggered', onTriggered));
  }
}

class _DebugOverlayTriggerDetectorState
    extends State<DebugOverlayTriggerDetector> {
  /// The current positions of all pointers that are down.
  final _pointers = <int, Offset>{};

  /// The positions of the two pointers when [_holdTimer] was started.
  var _holdStarts = <int, Offset>{};
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: .translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: widget.child,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.position;
    _restartHold();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _pointers[event.pointer] = event.position;

    final start = _holdStarts[event.pointer];
    if (_holdTimer != null &&
        start != null &&
        (event.position - start).distance > kTouchSlop) {
      _cancelHold();
    }
  }

  void _handlePointerEnd(PointerEvent event) {
    _pointers.remove(event.pointer);
    _restartHold();
  }

  void _restartHold() {
    _cancelHold();
    if (!widget.trigger.twoFingerHold || _pointers.length != 2) return;

    _holdStarts = Map.of(_pointers);
    _holdTimer = Timer(widget.trigger.holdDuration, () {
      _holdTimer = null;
      widget.onTriggered();
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  bool _handleKeyEvent(KeyEvent event) {
    final shortcut = widget.trigger.keyboardShortcut;
    if (shortcut == null || event is! KeyDownEvent) return false;
    if (!shortcut.accepts(event, HardwareKeyboard.instance)) return false;

    widget.onTriggered();
    return true;
  }
}
