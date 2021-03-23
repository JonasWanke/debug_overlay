import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:black_hole_flutter/black_hole_flutter.dart';

class DebugHelper extends StatelessWidget {
  const DebugHelper({required this.title, required this.child});

  final Widget title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DefaultTextStyle(
          style: context.textTheme.subtitle1!,
          child: title,
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }
}

class DiagnosticsBasedDebugHelper extends StatelessWidget {
  const DiagnosticsBasedDebugHelper({
    required this.title,
    required this.diagnosticsStream,
  });

  final Widget title;
  final Stream<List<DiagnosticsNode>> diagnosticsStream;

  @override
  Widget build(BuildContext context) {
    return DebugHelper(
      title: title,
      child: StreamBuilder<List<DiagnosticsNode>>(
        stream: diagnosticsStream,
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

          return Text(nodes
              .map((it) => it.toStringDeep(minLevel: DiagnosticLevel.fine))
              .join('\n'));
        },
      ),
    );
  }
}
