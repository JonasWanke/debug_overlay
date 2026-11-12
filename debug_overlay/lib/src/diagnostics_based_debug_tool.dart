import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:material_ui/material_ui.dart';

import 'debug_tool.dart';
import 'utils/level_selector.dart';

/// A [DebugTool] that displays a [Stream] of [DiagnosticsNode]s and allows the
/// user to filter them.
///
/// Unfortunately, this tool only works in debug mode because stringifying of
/// [DiagnosticsNode]s only works in debug mode.
abstract class DiagnosticsBasedDebugTool({
  required super.icon,
  required super.title,
}) extends DebugTool {
  var _minLevel = DiagnosticLevel.debug;

  @override
  bool get isSearchable => true;

  /// The diagnostics to display.
  ///
  /// This is called whenever the content is rebuilt, so expensive results
  /// should be cached.
  Stream<List<DiagnosticsNode>> diagnosticsStream(BuildContext context);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      DiagnosticLevelSelector(
        value: _minLevel,
        onSelected: (level) {
          _minLevel = level;
          notifyListeners();
        },
      ),
    ];
  }

  @override
  Widget buildSliver(BuildContext context) {
    return SliverPadding(
      padding: const .symmetric(horizontal: 16),
      sliver: StreamBuilder(
        stream: diagnosticsStream(context),
        builder: (context, snapshot) {
          final error = snapshot.error;
          if (error != null) {
            assert(() {
              // ignore: avoid_print
              print('Error in debug tool: $error\n${snapshot.stackTrace!}');
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
              .map((it) => it.toStringDeep(minLevel: _minLevel))
              .where((it) => matchesSearch([it]))
              .map(Text.new)
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
