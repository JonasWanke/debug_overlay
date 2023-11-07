import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DiagnosticLevelSelector extends StatelessWidget {
  const DiagnosticLevelSelector({
    super.key,
    required this.value,
    required this.onSelected,
  });

  final DiagnosticLevel value;
  final ValueSetter<DiagnosticLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      initialValue: value,
      tooltip: 'Select the minimum diagnostics level to display',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final level in DiagnosticLevel.values)
          PopupMenuItem(value: level, child: Text(level.title)),
      ],
      icon: const Icon(Icons.filter_alt_outlined),
    );
  }

  static IconData levelToIcon(DiagnosticLevel level) {
    return switch (level) {
      DiagnosticLevel.hidden => Icons.all_inclusive_outlined,
      DiagnosticLevel.fine => Icons.bubble_chart_outlined,
      DiagnosticLevel.debug => Icons.bug_report_outlined,
      DiagnosticLevel.info => Icons.info_outline,
      DiagnosticLevel.warning => Icons.warning_outlined,
      DiagnosticLevel.hint => Icons.privacy_tip_outlined,
      DiagnosticLevel.summary => Icons.subject,
      DiagnosticLevel.error => Icons.error_outlined,
      DiagnosticLevel.off => Icons.not_interested_outlined,
    };
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty('value', value))
      ..add(ObjectFlagProperty.has('onSelected', onSelected));
  }
}

extension on DiagnosticLevel {
  String get title {
    return switch (this) {
      DiagnosticLevel.hidden => 'All',
      DiagnosticLevel.fine => '≥ Fine',
      DiagnosticLevel.debug => '≥ Debug',
      DiagnosticLevel.info => '≥ Info',
      DiagnosticLevel.warning => '≥ Warning',
      DiagnosticLevel.hint => '≥ Hint',
      DiagnosticLevel.summary => '≥ Summary',
      DiagnosticLevel.error => '≥ Error',
      DiagnosticLevel.off => 'None',
    };
  }
}
