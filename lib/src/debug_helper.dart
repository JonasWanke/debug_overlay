import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'utils/level_selector.dart';

class DebugHelper extends StatelessWidget {
  const DebugHelper({
    super.key,
    required this.title,
    this.actions = const [],
    required this.sliver,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Widget title;
  final List<Widget> actions;

  final Widget sliver;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
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
    );

    return MultiSliver(
      children: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: header,
          ),
        ),
        SliverPadding(padding: contentPadding, sliver: sliver),
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
      sliver: StreamBuilder(
        stream: widget.diagnosticsStream,
        builder: (context, snapshot) {
          final error = snapshot.error;
          if (error != null) {
            assert(() {
              // ignore: avoid_print
              print('Error in debug helper: $error\n${snapshot.stackTrace!}');
              return true;
            }());

            return SliverToBoxAdapter(
              child: Center(child: Text('$error\n${snapshot.stackTrace!}')),
            );
          }

          final nodes = snapshot.data;
          if (nodes == null) {
            return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final entries = nodes
              .where((it) => it.level.index >= _minLevel.index)
              .map((it) => Text(it.toStringDeep(minLevel: _minLevel)))
              .toList();
          if (entries.isEmpty) {
            return SliverToBoxAdapter(
              child: Center(
                child: Text('Empty', style: context.textTheme.bodySmall),
              ),
            );
          }
          return SliverList.list(children: entries);
        },
      ),
    );
  }
}
