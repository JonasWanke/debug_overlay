import 'dart:async';
import 'dart:convert';
// TODO(JonasWanke): Remove the import when upgrading Flutter
// ignore: unnecessary_import
import 'dart:ui';

import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:json_view/json_view.dart';

import '../../debug_helper.dart';
import '../../utils/level_selector.dart';
import 'data.dart';

class LogsDebugHelper extends StatefulWidget {
  const LogsDebugHelper(
    this.logs, {
    super.key,
    this.initialMinLevel = DiagnosticLevel.debug,
    this.title = const Text('Logs'),
  });

  final LogCollection logs;
  final DiagnosticLevel initialMinLevel;
  final Widget title;

  @override
  State<LogsDebugHelper> createState() => _LogsDebugHelperState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('logs', logs))
      ..add(EnumProperty('initialMinLevel', initialMinLevel));
  }
}

class _LogsDebugHelperState extends State<LogsDebugHelper> {
  late var _minLevel = widget.initialMinLevel;
  var _isOldestFirst = true;

  @override
  Widget build(BuildContext context) {
    Widget sortIcon = const Icon(Icons.sort);
    if (!_isOldestFirst) {
      sortIcon = Transform.scale(scaleY: -1, child: sortIcon);
    }
    final sortButton = IconButton(
      tooltip: _isOldestFirst ? 'Show newest first' : 'Show oldest first',
      onPressed: () => setState(() => _isOldestFirst = !_isOldestFirst),
      icon: sortIcon,
    );

    return DebugHelper(
      title: widget.title,
      actions: [
        IconButton(
          tooltip: 'Copy logs',
          onPressed: () async =>
              _copyLogsToClipboard(context, widget.logs.logs),
          icon: const Icon(Icons.copy_outlined),
        ),
        IconButton(
          tooltip: 'Clear logs',
          onPressed: widget.logs.clear,
          icon: const Icon(Icons.delete_outlined),
        ),
        sortButton,
        DiagnosticLevelSelector(
          value: _minLevel,
          onSelected: (level) => setState(() => _minLevel = level),
        ),
      ],
      contentPadding: EdgeInsets.zero,
      sliver: ValueListenableBuilder(
        valueListenable: widget.logs.listenable,
        builder: (context, logs, _) {
          if (logs.isEmpty) {
            return SliverToBoxAdapter(
              child: Center(
                child: Text(
                  'No logs available.',
                  style: context.textTheme.bodySmall!.copyWith(
                    color: context
                        .theme.scaffoldBackgroundColor.mediumEmphasisOnColor,
                  ),
                ),
              ),
            );
          }

          var filteredLogs =
              logs.where((it) => it.level.index >= _minLevel.index).toList();
          if (!_isOldestFirst) {
            filteredLogs = filteredLogs.reversed.toList();
          }
          return SliverImplicitlyAnimatedList(
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

    final icon = Icon(
      DiagnosticLevelSelector.levelToIcon(log.level),
      color: color,
    );

    final textStyle = TextStyle(color: color);
    final title = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: formattedTimestamp,
            style: context.textTheme.bodySmall!.copyWith(
              color: color.withValues(alpha: 0.6),
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(text: ' ${log.message}'),
        ],
      ),
      style: textStyle,
    );

    if (log.error == null && log.stackTrace == null) {
      return _LogEntryLine(
        onLongPress: () async => _copyLogsToClipboard(context, [log]),
        leading: icon,
        title: title,
      );
    }

    return _ExpansionTile(
      onLongPress: () async => _copyLogsToClipboard(context, [log]),
      leading: icon,
      title: title,
      isInitiallyExpanded: log.level.index >= DiagnosticLevel.error.index,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (log.error != null) ...[
              _buildSubtitle(context, '${log._errorLabel}:'),
              _buildError(context),
              const SizedBox(height: 8),
            ],
            if (log.stackTrace != null) ...[
              _buildSubtitle(context, 'Stack Trace:'),
              Text(log.stackTrace!.toString(), style: textStyle),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTextColor(BuildContext context) {
    final theme = context.theme;
    final brightness = theme.scaffoldBackgroundColor.estimatedBrightness;
    return switch (log.level) {
      DiagnosticLevel.hidden => brightness.disabledOnColor,
      DiagnosticLevel.fine => brightness.disabledOnColor,
      DiagnosticLevel.debug => brightness.mediumEmphasisOnColor,
      DiagnosticLevel.info => brightness.highEmphasisOnColor,
      DiagnosticLevel.warning => Colors.orange,
      DiagnosticLevel.hint => brightness.mediumEmphasisOnColor,
      DiagnosticLevel.summary => brightness.highEmphasisOnColor,
      DiagnosticLevel.error => theme.colorScheme.error,
      DiagnosticLevel.off => Colors.purple,
    };
  }

  Widget _buildSubtitle(BuildContext context, String text) =>
      Text(text, style: Theme.of(context).textTheme.titleSmall);
  Widget _buildError(BuildContext context) {
    if (_errorToJsonListOrMap(log.error) case final json?) {
      return JsonView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        json: json,
      );
    }

    return Text(
      _stringify(log.error as Object),
      style: TextStyle(color: _getTextColor(context)),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('log', log));
  }
}

Future<void> _copyLogsToClipboard(BuildContext context, List<Log> logs) async {
  await Clipboard.setData(
    ClipboardData(
      text: logs
          .expand(
            (log) => [
              '${log.timestamp}: ${log.message}',
              if (log.error != null)
                '${log._errorLabel}: ${_stringify(log.error as Object)}',
              if (log.stackTrace != null) 'Stack Trace: ${log.stackTrace}',
            ],
          )
          .join('\n'),
    ),
  );
  if (!context.mounted) return;

  context.scaffoldMessenger
      .showSnackBar(const SnackBar(content: Text('Copied!')));
}

extension on Log {
  String get _errorLabel =>
      level.index >= DiagnosticLevel.error.index ? 'Error' : 'Data';
}

dynamic _errorToJsonListOrMap(dynamic error) {
  bool isJson(Object? object) {
    if (object == null || object is bool || object is num || object is String) {
      return true;
    }
    if (object is List) return object.every(isJson);
    if (object is Map) {
      return object.keys.every((it) => it is String) &&
          object.values.every(isJson);
    }

    try {
      // ignore: avoid_dynamic_calls
      (object as dynamic).toJson();
      return true;
    } catch (_) {}
    return false;
  }

  bool isJsonListOrMap(Object? object) {
    if (object is List || object is Map) return isJson(object);

    try {
      // ignore: avoid_dynamic_calls
      return isJsonListOrMap((object as dynamic).toJson());
    } catch (_) {}
    return false;
  }

  if (!isJsonListOrMap(error!)) return null;

  dynamic toJson(Object? object) {
    if (object == null || object is bool || object is num || object is String) {
      return object;
    }
    if (object is List) return object.map(toJson).toList();
    if (object is Map) {
      final entries = <String, dynamic>{};
      for (final entry in object.entries) {
        if (entry.key is! String) return null;
        entries[entry.key as String] = toJson(entry.value);
      }
      return entries;
    }

    try {
      // ignore: avoid_dynamic_calls
      return toJson((object as dynamic).toJson());
    } catch (_) {}
    try {
      return '$object';
    } catch (_) {}
    return describeIdentity(object);
  }

  return toJson(error!);
}

String _stringify(Object object) {
  if (object is String) return object.trim();
  if (object is DiagnosticsNode) return object.toStringDeep();

  try {
    // ignore: avoid_dynamic_calls
    (object as dynamic).toJson();
    // It supports `toJson()`.

    dynamic toEncodable(dynamic object) {
      try {
        // ignore: avoid_dynamic_calls
        return object.toJson();
      } catch (_) {}
      try {
        return '$object';
      } catch (_) {}
      return describeIdentity(object);
    }

    return JsonEncoder.withIndent('  ', toEncodable).convert(object);
  } catch (_) {}

  try {
    return '$object'.trim();
  } catch (_) {}
  return describeIdentity(object);
}

class _LogEntryLine extends StatelessWidget {
  const _LogEntryLine({
    this.onTap,
    required this.onLongPress,
    required this.leading,
    required this.title,
    this.trailing,
  });

  final VoidCallback? onTap;
  final VoidCallback onLongPress;
  final Widget leading;
  final Widget title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final child = IconTheme.merge(
      data: const IconThemeData(size: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 4),
          Expanded(child: title),
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: child,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty.has('onTap', onTap))
      ..add(ObjectFlagProperty.has('onLongPress', onLongPress));
  }
}

// Based on [ExpansionTile]

class _ExpansionTile extends StatefulWidget {
  const _ExpansionTile({
    required this.onLongPress,
    required this.leading,
    required this.title,
    required this.child,
    this.isInitiallyExpanded = false,
  });

  final VoidCallback onLongPress;
  final Widget leading;
  final Widget title;
  final Widget child;
  final bool isInitiallyExpanded;

  @override
  State<_ExpansionTile> createState() => _ExpansionTileState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty.has('onLongPress', onLongPress))
      ..add(DiagnosticsProperty('isInitiallyExpanded', isInitiallyExpanded));
  }
}

class _ExpansionTileState extends State<_ExpansionTile>
    with SingleTickerProviderStateMixin {
  static const _kExpand = Duration(milliseconds: 200);

  static final _easeOutTween = CurveTween(curve: Curves.easeOut);
  static final _easeInTween = CurveTween(curve: Curves.easeIn);
  static final _halfTween = Tween<double>(begin: 0, end: 0.5);

  final _borderTween = ShapeBorderTween();

  late final _animationController =
      AnimationController(duration: _kExpand, vsync: this);
  late final _iconTurns =
      _animationController.drive(_halfTween.chain(_easeInTween));
  late final _heightFactor = _animationController.drive(_easeInTween);
  late final _border =
      _animationController.drive(_borderTween.chain(_easeOutTween));

  var _isExpanded = false;

  @override
  void initState() {
    super.initState();

    _isExpanded = PageStorage.maybeOf(context)?.readState(context) as bool? ??
        widget.isInitiallyExpanded;
    if (_isExpanded) _animationController.value = 1.0;
  }

  @override
  void didChangeDependencies() {
    final theme = Theme.of(context);
    _borderTween
      ..begin = const Border(
        top: BorderSide(color: Colors.transparent),
        bottom: BorderSide(color: Colors.transparent),
      )
      ..end = Border(
        top: BorderSide(color: theme.dividerColor),
        bottom: BorderSide(color: theme.dividerColor),
      );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        unawaited(
          _animationController.reverse().then((value) {
            if (!mounted) return;
            setState(() {
              // Rebuild without widget.children.
            });
          }),
        );
      }
      PageStorage.maybeOf(context)?.writeState(context, _isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = !_isExpanded && _animationController.isDismissed;

    final header = _LogEntryLine(
      onTap: _toggleExpansion,
      onLongPress: widget.onLongPress,
      leading: widget.leading,
      title: widget.title,
      trailing: RotationTransition(
        turns: _iconTurns,
        child: const Icon(Icons.expand_more),
      ),
    );

    return AnimatedBuilder(
      animation: _animationController.view,
      child: Offstage(
        offstage: isClosed,
        child: TickerMode(enabled: !isClosed, child: widget.child),
      ),
      builder: (context, child) => DecoratedBox(
        decoration: ShapeDecoration(shape: _border.value!),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            ClipRect(
              child: Center(heightFactor: _heightFactor.value, child: child),
            ),
          ],
        ),
      ),
    );
  }
}
