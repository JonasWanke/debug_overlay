import 'dart:convert';
import 'dart:ui';

import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';

import '../../debug_helper.dart';
import '../../utils/level_selector.dart';
import 'data.dart';

class LogsDebugHelper extends StatefulWidget {
  const LogsDebugHelper(
    this.logs, {
    this.title = const Text('Logs'),
  });

  final LogCollection logs;

  final Widget title;

  @override
  State<LogsDebugHelper> createState() => _LogsDebugHelperState();
}

class _LogsDebugHelperState extends State<LogsDebugHelper> {
  var _minLevel = DiagnosticLevel.debug;
  @override
  Widget build(BuildContext context) {
    return DebugHelper(
      title: widget.title,
      actions: [
        IconButton(
          tooltip: 'Clear logs',
          onPressed: widget.logs.clear,
          icon: const Icon(Icons.delete_outlined),
        ),
        DiagnosticLevelSelector(
          value: _minLevel,
          onSelected: (level) => setState(() => _minLevel = level),
        ),
      ],
      contentPadding: EdgeInsets.zero,
      child: ValueListenableBuilder<List<Log>>(
        valueListenable: widget.logs.listenable,
        builder: (context, logs, _) {
          if (logs.isEmpty) {
            return Center(
              child: Text(
                'No logs available.',
                style: context.textTheme.caption!.copyWith(
                  color: context
                      .theme.scaffoldBackgroundColor.mediumEmphasisOnColor,
                ),
              ),
            );
          }

          final filteredLogs =
              logs.where((it) => it.level.index >= _minLevel.index).toList();
          return ImplicitlyAnimatedList<Log>(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemData: filteredLogs,
            itemBuilder: (context, data) => LogEntryWidget(data),
          );
        },
      ),
    );
  }
}

class LogEntryWidget extends StatelessWidget {
  LogEntryWidget(this.log) : super(key: ValueKey(log));

  final Log log;

  @override
  Widget build(BuildContext context) {
    // We don't show the date to save space.
    final rawTimestamp = log.timestamp.toString();
    final timeStartIndex = rawTimestamp.indexOf(' ') + 1;
    final formattedTimestamp = rawTimestamp.substring(timeStartIndex);

    final color = _getTextColor(context);
    final content = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: formattedTimestamp,
            style: context.textTheme.caption!.copyWith(
              color: color.withOpacity(0.6),
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(text: ' ${log.message}'),
          ..._toText(context, 'Error', log.error),
          ..._toText(
            context,
            'Stack Trace',
            log.stackTrace,
            addLineBreakAfterTitle: true,
          ),
        ],
        style: TextStyle(color: color),
      ),
    );

    return InkWell(
      onLongPress: () => _copyToClipboard(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              DiagnosticLevelSelector.levelToIcon(log.level),
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _toText(
    BuildContext context,
    String title,
    dynamic object, {
    bool addLineBreakAfterTitle = false,
  }) {
    final string = _stringify(object);
    if (string == null) return [];

    return [
      TextSpan(
        text: '\n$title:${addLineBreakAfterTitle ? '\n' : ' '}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      TextSpan(text: string),
    ];
  }

  Color _getTextColor(BuildContext context) {
    final theme = context.theme;
    final brightness = theme.scaffoldBackgroundColor.estimatedBrightness;
    switch (log.level) {
      case DiagnosticLevel.hidden:
        return brightness.disabledOnColor;
      case DiagnosticLevel.fine:
        return brightness.disabledOnColor;
      case DiagnosticLevel.debug:
        return brightness.mediumEmphasisOnColor;
      case DiagnosticLevel.info:
        return brightness.highEmphasisOnColor;
      case DiagnosticLevel.warning:
        return Colors.orange;
      case DiagnosticLevel.hint:
        return brightness.mediumEmphasisOnColor;
      case DiagnosticLevel.summary:
        return brightness.highEmphasisOnColor;
      case DiagnosticLevel.error:
        return theme.errorColor;
      case DiagnosticLevel.off:
        return Colors.purple;
    }
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final error = _stringify(log.error);
    final stackTrace = _stringify(log.stackTrace);
    final text = [
      '${log.timestamp}: ${log.message}',
      if (error != null) 'Error: $error',
      if (stackTrace != null) 'Stack Trace: $stackTrace',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    context.scaffoldMessenger
        .showSnackBar(const SnackBar(content: Text('Copied!')));
  }

  String? _stringify(dynamic object) {
    if (object == null) return null;
    if (object is String) return object.trim();
    if (object is DiagnosticsNode) return object.toStringDeep();

    try {
      object.toJson();
      // It supports `toJson()`.

      dynamic toEncodable(dynamic object) {
        try {
          return object.toJson();
        } catch (_) {
          try {
            return '$object';
          } catch (_) {
            return describeIdentity(object);
          }
        }
      }

      return JsonEncoder.withIndent('  ', toEncodable).convert(object);
    } catch (_) {}

    try {
      return '$object'.trim();
    } catch (_) {
      return describeIdentity(object);
    }
  }
}
