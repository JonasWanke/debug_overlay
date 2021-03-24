import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'utils/level_selector.dart';

class DebugHelper extends StatelessWidget {
  const DebugHelper({
    required this.title,
    this.actions = const [],
    required this.child,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Widget title;
  final List<Widget> actions;

  final Widget child;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
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
        ),
        SizedBox(height: 8),
        Padding(padding: contentPadding, child: child),
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
        DiagnosticLevelSelector(
          value: _minLevel,
          onSelected: (level) => setState(() => _minLevel = level),
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
}
