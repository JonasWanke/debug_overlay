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

  static IconData levelToIcon(DiagnosticLevel level) => switch (level) {
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty('value', value))
      ..add(ObjectFlagProperty.has('onSelected', onSelected));
  }
}

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
