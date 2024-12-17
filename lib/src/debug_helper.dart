import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'utils/level_selector.dart';

class DebugHelper extends StatelessWidget {
  const DebugHelper({
    super.key,
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: DefaultTextStyle(
                  style: context.textTheme.titleMedium!,
                  child: title,
                ),
              ),
              ...actions,
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(padding: contentPadding, child: child),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('contentPadding', contentPadding));
  }
}

/// A [DebugHelper] that displays a [Stream] of [DiagnosticsNode]s and allows
/// the user to filter them.
///
/// Unfortunately, this widget only works in debug mode because stringifying of
/// [DiagnosticsNode]s only works in debug mode.
class DiagnosticsBasedDebugHelper extends StatefulWidget {
  const DiagnosticsBasedDebugHelper({
    super.key,
    required this.title,
    required this.diagnosticsStream,
  });

  final Widget title;
  final Stream<List<DiagnosticsNode>> diagnosticsStream;

  @override
  State<DiagnosticsBasedDebugHelper> createState() =>
      _DiagnosticsBasedDebugHelperState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('diagnosticsStream', diagnosticsStream));
  }
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
      child: StreamBuilder(
        stream: widget.diagnosticsStream,
        builder: (context, snapshot) {
          final error = snapshot.error;
          if (error != null) {
            assert(() {
              // ignore: avoid_print
              print('Error in debug helper: $error\n${snapshot.stackTrace!}');
              return true;
            }());

            return Center(child: Text('$error\n${snapshot.stackTrace!}'));
          }

          final nodes = snapshot.data;
          if (nodes == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final text = nodes
              .where((it) => it.level.index >= _minLevel.index)
              .map((it) => it.toStringDeep(minLevel: _minLevel))
              .join('\n');
          if (text.isEmpty) {
            return Center(
              child: Text('Empty', style: context.textTheme.bodySmall),
            );
          }
          return Text(text);
        },
      ),
    );
  }
}
