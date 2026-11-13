import 'package:material_ui/material_ui.dart';

import '../debug_tool_action.dart';

/// An action to select the minimum [DiagnosticLevel] to display.
DebugToolChoice<DiagnosticLevel> diagnosticLevelChoice({
  required DiagnosticLevel value,
  required ValueSetter<DiagnosticLevel> onSelected,
}) {
  return DebugToolChoice(
    icon: Icons.filter_alt_outlined,
    label: 'Minimum level',
    options: DiagnosticLevel.values,
    value: value,
    onSelected: onSelected,
    optionLabel: (level) => level.title,
  );
}

IconData diagnosticLevelToIcon(DiagnosticLevel level) => switch (level) {
  .hidden => Icons.all_inclusive_outlined,
  .fine => Icons.bubble_chart_outlined,
  .debug => Icons.bug_report_outlined,
  .info => Icons.info_outline,
  .warning => Icons.warning_outlined,
  .hint => Icons.privacy_tip_outlined,
  .summary => Icons.subject,
  .error => Icons.error_outlined,
  .off => Icons.not_interested_outlined,
};

extension on DiagnosticLevel {
  String get title => switch (this) {
    .hidden => 'All',
    .fine => '≥ Fine',
    .debug => '≥ Debug',
    .info => '≥ Info',
    .warning => '≥ Warning',
    .hint => '≥ Hint',
    .summary => '≥ Summary',
    .error => '≥ Error',
    .off => 'None',
  };
}
