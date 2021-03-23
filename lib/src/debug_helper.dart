import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DebugHelper extends StatelessWidget {
  const DebugHelper({
    required this.title,
    this.actions = const [],
    required this.child,
  });

  final Widget title;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: DefaultTextStyle(
                style: context.textTheme.subtitle1!,
                child: title,
              ),
            ),
            ...actions,
          ],
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }
}

class DiagnosticsBasedDebugHelper extends StatefulWidget {
  const DiagnosticsBasedDebugHelper({
    required this.title,
    required this.diagnosticsStream,
  });

  final Widget title;
  final Stream<List<DiagnosticsNode>> diagnosticsStream;

  @override
  _DiagnosticsBasedDebugHelperState createState() =>
      _DiagnosticsBasedDebugHelperState();
}

class _DiagnosticsBasedDebugHelperState
    extends State<DiagnosticsBasedDebugHelper> {
  var _minLevel = DiagnosticLevel.debug;

  @override
  Widget build(BuildContext context) {
    return DebugHelper(
      title: widget.title,
      actions: [
        PopupMenuButton<DiagnosticLevel>(
          onSelected: (level) {
            setState(() => _minLevel = level);
          },
          initialValue: _minLevel,
          child: Icon(_levelToIcon(_minLevel)),
          itemBuilder: (context) => [
            for (final level in DiagnosticLevel.values)
              PopupMenuItem(
                value: level,
                child: Text(describeEnum(level)),
              ),
          ],
        ),
      ],
      child: StreamBuilder<List<DiagnosticsNode>>(
        stream: widget.diagnosticsStream,
        builder: (context, snapshot) {
          final error = snapshot.error;
          if (error != null) {
            assert(() {
              // ignore: avoid_print
              print('Error in debug helper: $error\n${snapshot.stackTrace!}');
              return true;
            }());

            return Center(
              child: Text('$error\n${snapshot.stackTrace!}'),
            );
          }

          final nodes = snapshot.data;
          if (nodes == null) return Center(child: CircularProgressIndicator());

          return Text(
            nodes
                .where((it) => it.level.index >= _minLevel.index)
                .map((it) => it.toStringDeep(minLevel: _minLevel))
                .join('\n'),
          );
        },
      ),
    );
  }

  IconData _levelToIcon(DiagnosticLevel level) {
    switch (level) {
      case DiagnosticLevel.hidden:
        return Icons.all_inclusive_outlined;
      case DiagnosticLevel.fine:
        return Icons.bubble_chart_outlined;
      case DiagnosticLevel.debug:
        return Icons.bug_report_outlined;
      case DiagnosticLevel.info:
        return Icons.info_outline;
      case DiagnosticLevel.warning:
        return Icons.warning_outlined;
      case DiagnosticLevel.hint:
        return Icons.privacy_tip_outlined;
      case DiagnosticLevel.summary:
        return Icons.subject;
      case DiagnosticLevel.error:
        return Icons.error_outlined;
      case DiagnosticLevel.off:
        return Icons.not_interested_outlined;
    }
  }
}
