import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import 'debug_overlay.dart';

/// The [DebugOverlayMode.collapsed] representation of the [DebugOverlay]: a
/// draggable bubble that expands on tap and closes the overlay when dropped on
/// the dismiss target.
///
/// The bubble fills its parent, but only the bubble itself (and the dismiss
/// target while dragging) is hit-testable.
class const DebugOverlayBubble({
  super.key,

  /// Where the bubble rests within the safe area. The x-value is always
  /// `-1` (left edge) or `1` (right edge).
  required final Alignment alignment,
  required final ValueChanged<Alignment> onAlignmentChanged,
}) extends StatefulWidget {
  @override
  State<DebugOverlayBubble> createState() => _DebugOverlayBubbleState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('alignment', alignment))
      ..add(
        ObjectFlagProperty<ValueChanged<Alignment>>.has(
          'onAlignmentChanged',
          onAlignmentChanged,
        ),
      );
  }
}

const _bubbleSize = 48.0;
const _bubbleMargin = -8.0;
const _targetSize = 56.0;
const _targetBottomMargin = 32.0;

class _DebugOverlayBubbleState extends State<DebugOverlayBubble> {
  /// The top-left position of the bubble while it's being dragged, or `null`
  /// if it rests at [DebugOverlayBubble.alignment].
  Offset? _dragPosition;

  @override
  Widget build(BuildContext context) {
    final padding = context.mediaQuery.padding;
    return LayoutBuilder(
      builder: (context, constraints) {
        final area = constraints.biggest;
        const bubbleSizeOffset = Offset(_bubbleSize, _bubbleSize);
        final bounds = padding
            .deflateRect(Offset.zero & (area - bubbleSizeOffset as Size))
            .deflate(_bubbleMargin);
        final targetCenter = Offset(
          area.width / 2,
          area.height - padding.bottom - _targetBottomMargin - _targetSize / 2,
        );

        final isDragging = _dragPosition != null;
        final position = _dragPosition ?? widget.alignment.withinRect(bounds);
        final isOverTarget =
            isDragging &&
            (position + bubbleSizeOffset / 2 - targetCenter).distance <
                _targetSize;

        final bubble = AnimatedPositioned(
          // No animation while the finger is in control.
          duration: isDragging ? .zero : const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            // Include the movement before the drag was recognized so the
            // bubble doesn't lag behind the finger.
            dragStartBehavior: .down,
            onPanStart: (_) => setState(() => _dragPosition = position),
            onPanUpdate: (details) => setState(
              () => _dragPosition = _clampToArea(
                _dragPosition! + details.delta,
                area,
              ),
            ),
            onPanEnd: (_) => _handleDragEnd(bounds, isOverTarget),
            onPanCancel: () => setState(() => _dragPosition = null),
            child: _buildBubble(context),
          ),
        );
        return Stack(
          children: [
            if (isDragging) _buildTarget(context, targetCenter, isOverTarget),
            bubble,
          ],
        );
      },
    );
  }

  Widget _buildBubble(BuildContext context) {
    final colors = context.theme.colorScheme;
    return Material(
      shape: const CircleBorder(),
      elevation: 6,
      color: colors.primaryContainer,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: DebugOverlay.expand,
        child: SizedBox.square(
          dimension: _bubbleSize,
          child: Icon(Icons.bug_report, color: colors.onPrimaryContainer),
        ),
      ),
    );
  }

  Widget _buildTarget(BuildContext context, Offset center, bool isHighlighted) {
    final colors = context.theme.colorScheme;
    return Positioned(
      left: center.dx - _targetSize / 2,
      top: center.dy - _targetSize / 2,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: isHighlighted ? 1.2 : 1,
        child: Material(
          shape: const CircleBorder(),
          elevation: 4,
          color: isHighlighted ? colors.error : colors.surfaceContainerHigh,
          child: SizedBox.square(
            dimension: _targetSize,
            child: Icon(
              Icons.close,
              color: isHighlighted ? colors.onError : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Offset _clampToArea(Offset position, Size area) {
    return Offset(
      position.dx.clamp(0, area.width - _bubbleSize),
      position.dy.clamp(0, area.height - _bubbleSize),
    );
  }

  void _handleDragEnd(Rect bounds, bool isOverTarget) {
    final position = _dragPosition!;
    setState(() => _dragPosition = null);

    if (isOverTarget) {
      DebugOverlay.close();
      return;
    }

    // Snap to the closest horizontal edge and keep the vertical position.
    final centerX = position.dx + _bubbleSize / 2;
    final isOnRight = centerX > (bounds.left + bounds.right + _bubbleSize) / 2;
    final fraction = bounds.height <= 0
        ? 0.0
        : ((position.dy - bounds.top) / bounds.height).clamp(0.0, 1.0);
    widget.onAlignmentChanged(Alignment(isOnRight ? 1 : -1, fraction * 2 - 1));
  }
}
