import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../debug_helper.dart';
import '../../debug_tool.dart';
import 'data.dart';

class const NetworkDebugHelper(
  final NetworkRequestCollection requests, {
  super.key,
}) extends StatefulWidget {
  static DebugTool tool(NetworkRequestCollection requests) {
    return DebugTool(
      icon: Icons.swap_vert,
      title: 'Network',
      sliver: NetworkDebugHelper(requests),
    );
  }

  @override
  State<NetworkDebugHelper> createState() => _NetworkDebugHelperState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('requests', requests));
  }
}

class _NetworkDebugHelperState extends State<NetworkDebugHelper> {
  var _onlyErrors = false;

  @override
  Widget build(BuildContext context) {
    return DebugHelper(
      actions: [
        (_onlyErrors ? IconButton.filledTonal : IconButton.new)(
          tooltip: _onlyErrors ? 'Show all requests' : 'Only show errors',
          onPressed: () => setState(() => _onlyErrors = !_onlyErrors),
          icon: const Icon(Icons.error_outline),
        ),
        IconButton(
          tooltip: 'Clear requests',
          onPressed: widget.requests.clear,
          icon: const Icon(Icons.delete_outlined),
        ),
      ],
      contentPadding: .zero,
      sliver: ValueListenableBuilder(
        valueListenable: widget.requests.listenable,
        builder: (context, requests, _) {
          // Newest first.
          final visible = [
            for (final request in requests.reversed)
              if (!_onlyErrors || _isError(request)) request,
          ];
          if (visible.isEmpty) {
            return SliverToBoxAdapter(
              child: Center(
                child: Text(
                  requests.isEmpty
                      ? 'No requests available.'
                      : 'No failed requests.',
                  style: context.textTheme.bodySmall!.copyWith(
                    color: context
                        .theme
                        .scaffoldBackgroundColor
                        .mediumEmphasisOnColor,
                  ),
                ),
              ),
            );
          }

          return SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) =>
                NetworkRequestWidget(visible[index]),
          );
        },
      ),
    );
  }

  /// Whether the request failed or received an error status code.
  bool _isError(NetworkRequest request) {
    final statusCode = request.statusCode;
    return request.hasFailed || (statusCode != null && statusCode >= 400);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('onlyErrors', value: _onlyErrors));
  }
}

// ignore: prefer_const_constructors_in_immutables
class NetworkRequestWidget(final NetworkRequest request)
    extends StatelessWidget {
  this : super(key: ValueKey(request.id));

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final color = _getStatusColor(context);
    final smallStyle = context.textTheme.bodySmall!;

    final title = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: request.method,
            style: const TextStyle(fontWeight: .bold),
          ),
          TextSpan(text: ' ${request.url}'),
        ],
      ),
      maxLines: 2,
      overflow: .ellipsis,
    );
    final subtitle = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: _statusText,
            style: TextStyle(color: color, fontWeight: .bold),
          ),
          TextSpan(text: '  $_detailsText'),
        ],
      ),
      style: smallStyle.copyWith(
        fontFeatures: [const FontFeature.tabularFigures()],
      ),
    );

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        dense: true,
        tilePadding: const .symmetric(horizontal: 16),
        childrenPadding: const .fromLTRB(16, 0, 16, 8),
        expandedCrossAxisAlignment: .stretch,
        expandedAlignment: .centerLeft,
        title: title,
        subtitle: subtitle,
        trailing: request.isInFlight
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        children: [
          Align(
            alignment: .centerRight,
            child: PopupMenuButton<_CopyOption>(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_outlined, size: 20),
              onSelected: (option) => _copy(context, option),
              itemBuilder: (context) => [
                for (final option in _CopyOption.values)
                  PopupMenuItem(
                    value: option,
                    enabled: _textFor(option) != null,
                    child: Text(option.label),
                  ),
              ],
            ),
          ),
          if (request.error != null)
            _Section(
              title: 'Error',
              child: _MonospaceText(
                [request.error, request.stackTrace].nonNulls.join('\n'),
                color: theme.colorScheme.error,
              ),
            ),
          _HeadersSection(
            title: 'Request Headers',
            headers: request.requestHeaders,
          ),
          _BodySection(title: 'Request Body', body: request.requestBody),
          _HeadersSection(
            title: 'Response Headers',
            headers: request.responseHeaders,
            emptyText: request.isInFlight ? 'Pending' : 'None',
          ),
          _BodySection(
            title: 'Response Body',
            body: request.responseBody,
            emptyText: request.isInFlight ? 'Pending' : 'None',
          ),
        ],
      ),
    );
  }

  String get _statusText {
    if (request.error != null) return 'Failed';
    final statusCode = request.statusCode;
    if (statusCode == null) return 'Pending';
    return '$statusCode';
  }

  /// The duration and start time, separated by spaces.
  String get _detailsText {
    return [
      _durationText,
      _startTimeText,
    ].where((it) => it.isNotEmpty).join('  ');
  }

  /// The local start time, e.g., `11:24:10.146`; we don't show the date to save
  /// space.
  String get _startTimeText => request.startTime.toString().substring(11, 23);

  String get _durationText {
    final duration = request.duration;
    if (duration == null) return '';
    if (duration.inSeconds >= 1) {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(3)} s';
    }
    return '${duration.inMilliseconds} ms';
  }

  Color _getStatusColor(BuildContext context) {
    final theme = context.theme;
    final statusCode = request.statusCode;
    if (request.error != null) return theme.colorScheme.error;
    if (statusCode == null) {
      return theme
          .scaffoldBackgroundColor
          .estimatedBrightness
          .mediumEmphasisOnColor;
    }
    if (statusCode >= 400) return theme.colorScheme.error;
    if (statusCode >= 300) return Colors.orange;
    return Colors.green;
  }

  Future<void> _copy(BuildContext context, _CopyOption option) async {
    final text = _textFor(option);
    if (text == null) return;

    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;

    context.scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Copied ${option.label.toLowerCase()}!')),
    );
  }

  /// Returns the text to copy for [option] or `null` if there's nothing to
  /// copy.
  String? _textFor(_CopyOption option) {
    String? headersTextOrNull(Map<String, String> headers) =>
        headers.isEmpty ? null : _headersText(headers);

    return switch (option) {
      .everything => _everythingText,
      .url => '${request.url}',
      .requestHeaders => headersTextOrNull(request.requestHeaders),
      .requestBody => request.requestBody,
      .responseHeaders => headersTextOrNull(request.responseHeaders),
      .responseBody => request.responseBody,
    };
  }

  String get _everythingText {
    String section(String title, Map<String, String> headers, String? body) {
      return [
        '$title Headers:',
        for (final entry in headers.entries) '${entry.key}: ${entry.value}',
        if (body != null) '$title Body:\n$body',
      ].join('\n');
    }

    return [
      '${request.method} ${request.url}',
      'Started: ${request.startTime}',
      '$_statusText $_durationText'.trim(),
      section('Request', request.requestHeaders, request.requestBody),
      section('Response', request.responseHeaders, request.responseBody),
      if (request.error != null) 'Error: ${request.error}',
    ].join('\n\n');
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('request', request));
  }
}

class const _HeadersSection({
  required final String title,
  required final Map<String, String> headers,
  final String emptyText = 'None',
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      child: headers.isEmpty
          ? _EmptyText(emptyText)
          : _MonospaceText(_headersText(headers)),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(DiagnosticsProperty('headers', headers))
      ..add(StringProperty('emptyText', emptyText));
  }
}

class const _BodySection({
  required final String title,
  required final String? body,
  final String emptyText = 'None',
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final body = this.body;
    return _Section(
      title: title,
      child: body == null ? _EmptyText(emptyText) : _MonospaceText(body),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('body', body))
      ..add(StringProperty('emptyText', emptyText));
  }
}

class const _Section({required final String title, required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .only(bottom: 8),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(title, style: context.textTheme.titleSmall),
          child,
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title));
  }
}

class const _MonospaceText(final String text, {final Color? color})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: context.textTheme.bodySmall!.copyWith(
        fontFamily: 'monospace',
        color: color,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('text', text))
      ..add(ColorProperty('color', color));
  }
}

class const _EmptyText(final String text) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.bodySmall!.copyWith(
        color: context.theme.scaffoldBackgroundColor.mediumEmphasisOnColor,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
  }
}

enum _CopyOption(final String label) {
  everything('Everything'),
  url('URL'),
  requestHeaders('Request headers'),
  requestBody('Request body'),
  responseHeaders('Response headers'),
  responseBody('Response body');
}

String _headersText(Map<String, String> headers) =>
    headers.entries.map((it) => '${it.key}: ${it.value}').join('\n');
