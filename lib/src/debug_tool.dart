import 'package:material_ui/material_ui.dart';

import 'debug_helper.dart';
import 'debug_overlay.dart';

/// A tab in the expanded [DebugOverlay].
///
/// Register tools via [DebugOverlay.tools], [DebugOverlay.prependTool], or
/// [DebugOverlay.appendTool].
class const DebugTool({
  /// The icon shown in the tab bar.
  required final IconData icon,

  /// A short name that is shown as the tooltip of the tab.
  required final String title,

  /// The content of the tab, which has to be a sliver, e.g., a [DebugHelper].
  required final Widget sliver,
});
