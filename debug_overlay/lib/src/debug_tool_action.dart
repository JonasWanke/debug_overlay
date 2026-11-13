import 'package:material_ui/material_ui.dart';

import 'debug_overlay.dart';
import 'debug_tool.dart';

/// An action in the header of the expanded [DebugOverlay].
///
/// Return actions from [DebugTool.buildActions]. If the header is too narrow
/// to show all of them as icon buttons, the last ones move into an overflow
/// menu that also shows their [label]s, so put the most important actions
/// first.
sealed class const DebugToolAction({
  /// The icon of the button in the header and the entry in the overflow menu.
  required final IconData icon,

  /// A short description, used as the tooltip and the text in the overflow
  /// menu.
  required final String label,
});

/// A [DebugToolAction] that runs [onPressed] when tapped.
///
/// Set [isSelected] for a toggle that is currently on.
final class const DebugToolButton({
  required super.icon,
  required super.label,
  required final VoidCallback? onPressed,
  final bool isSelected = false,
}) extends DebugToolAction;

/// A [DebugToolAction] that lets the user pick one of [options].
///
/// It opens a popup in the header and a submenu in the overflow menu.
final class const DebugToolChoice<T>({
  required super.icon,
  required super.label,
  required final List<T> options,
  required final T value,
  required final ValueChanged<T> onSelected,

  /// Returns the text of an option, defaulting to `toString()`.
  final String Function(T option)? optionLabel,
}) extends DebugToolAction {
  /// The options in a form that doesn't depend on [T], so that code handling
  /// any [DebugToolAction] doesn't have to deal with the type argument.
  List<DebugToolChoiceEntry> get entries {
    return [
      for (final option in options)
        (
          label: optionLabel?.call(option) ?? '$option',
          isSelected: option == value,
          select: () => onSelected(option),
        ),
    ];
  }
}

typedef DebugToolChoiceEntry = ({
  String label,
  bool isSelected,
  VoidCallback select,
});
