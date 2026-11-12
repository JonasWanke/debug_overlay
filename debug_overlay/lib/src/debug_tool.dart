import 'package:material_ui/material_ui.dart';

import 'debug_overlay.dart';

/// An entry in the tool picker of the expanded [DebugOverlay].
///
/// Register tools via [DebugOverlay.tools], [DebugOverlay.prependTool], or
/// [DebugOverlay.appendTool].
///
/// A tool is a long-lived object that owns its state, so filters and similar
/// settings survive switching to another tool or closing the overlay. After
/// changing state that affects [buildActions] or [buildSliver], call
/// [notifyListeners] to rebuild the overlay.
///
/// The overlay never disposes tools. If you create tools dynamically, dispose
/// them yourself after removing them from [DebugOverlay.tools].
abstract class DebugTool({
  /// The icon shown in the header and the tool picker.
  required final IconData icon,

  /// A short name that is shown in the header and the tool picker.
  required final String title,
}) extends ChangeNotifier {
  /// Buttons shown in the header of the overlay, next to [title].
  List<Widget> buildActions(BuildContext context) => const [];

  /// The content of the tool, which has to be a sliver.
  Widget buildSliver(BuildContext context);
}
