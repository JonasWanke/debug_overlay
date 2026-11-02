import 'dart:convert';

import 'package:flutter/foundation.dart';

/// A single HTTP request and, once available, its response or error.
///
/// This model is independent of any HTTP client. Use the `debug_overlay_http`
/// or `debug_overlay_dio` package, or call [NetworkRequestCollection.start],
/// [NetworkRequestCollection.complete], and [NetworkRequestCollection.fail]
/// to record requests from other clients.
@immutable
class NetworkRequest({
  required final int id,
  required final String method,
  required final Uri url,
  final Map<String, String> requestHeaders = const {},

  /// The request body as text or `null` if there is none.
  final String? requestBody,
  required final DateTime startTime,
  final int? statusCode,
  final String? reasonPhrase,
  final Map<String, String> responseHeaders = const {},

  /// The response body as text or `null` if there is none.
  final String? responseBody,

  /// The time between [startTime] and the end of the response or the error.
  ///
  /// This is `null` while the request is in flight.
  final Duration? duration,
  final Object? error,
  final StackTrace? stackTrace,
}) with Diagnosticable {
  /// Whether the request has neither completed nor failed yet.
  bool get isInFlight => duration == null;

  bool get hasFailed => error != null;

  NetworkRequest withResponse({
    required int statusCode,
    String? reasonPhrase,
    Map<String, String> headers = const {},
    String? body,
    required Duration duration,
  }) {
    return NetworkRequest(
      id: id,
      method: method,
      url: url,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      startTime: startTime,
      statusCode: statusCode,
      reasonPhrase: reasonPhrase,
      responseHeaders: headers,
      responseBody: body,
      duration: duration,
    );
  }

  NetworkRequest withError({
    required Object error,
    StackTrace? stackTrace,
    required Duration duration,
  }) {
    return NetworkRequest(
      id: id,
      method: method,
      url: url,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      startTime: startTime,
      duration: duration,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('id', id))
      ..add(StringProperty('method', method))
      ..add(DiagnosticsProperty('url', url))
      ..add(DiagnosticsProperty('startTime', startTime))
      ..add(IntProperty('statusCode', statusCode))
      ..add(DiagnosticsProperty('duration', duration))
      ..add(DiagnosticsProperty('error', error));
  }
}

class NetworkRequestCollection({
  this._maximumSize = 200,

  /// Whether to only store requests in debug mode.
  final bool onlyStoreRequestsInDebugMode = true,
}) {
  final _requests = ValueNotifier(<NetworkRequest>[]);
  ValueListenable<List<NetworkRequest>> get listenable => _requests;

  /// All stored requests, ordered from oldest to newest.
  List<NetworkRequest> get requests => listenable.value;

  int? _maximumSize;

  /// The maximum number of requests to store or `null` for unlimited storage.
  ///
  /// If more requests arrive, the oldest ones will be removed.
  int? get maximumSize => _maximumSize;
  set maximumSize(int? value) {
    _maximumSize = value;

    if (value != null && requests.length > value) {
      _requests.value = requests.sublist(requests.length - value);
    }
  }

  var _nextId = 0;

  /// Records the start of a request and returns its ID, which has to be passed
  /// to [complete] or [fail] later.
  int start({
    required String method,
    required Uri url,
    Map<String, String> requestHeaders = const {},
    String? requestBody,
    DateTime? startTime,
  }) {
    final id = _nextId++;
    if (onlyStoreRequestsInDebugMode && !kDebugMode) return id;

    final request = NetworkRequest(
      id: id,
      method: method.toUpperCase(),
      url: url,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      startTime: startTime ?? DateTime.now(),
    );
    final maximumSize = this.maximumSize;
    final startIndex = maximumSize != null && requests.length >= maximumSize
        ? requests.length - maximumSize + 1
        : 0;
    _requests.value = [...requests.sublist(startIndex), request];
    return id;
  }

  /// Records the response for the request with the given [id].
  ///
  /// Does nothing if the request is not stored (anymore).
  void complete(
    int id, {
    required int statusCode,
    String? reasonPhrase,
    Map<String, String> responseHeaders = const {},
    String? responseBody,
  }) {
    _update(
      id,
      (request, duration) => request.withResponse(
        statusCode: statusCode,
        reasonPhrase: reasonPhrase,
        headers: responseHeaders,
        body: responseBody,
        duration: duration,
      ),
    );
  }

  /// Records that the request with the given [id] failed without a response.
  ///
  /// Does nothing if the request is not stored (anymore).
  void fail(int id, Object error, [StackTrace? stackTrace]) {
    _update(
      id,
      (request, duration) => request.withError(
        error: error,
        stackTrace: stackTrace,
        duration: duration,
      ),
    );
  }

  void clear() => _requests.value = [];

  void _update(
    int id,
    NetworkRequest Function(NetworkRequest request, Duration duration) update,
  ) {
    // Newer requests are more likely to be updated.
    final index = requests.lastIndexWhere((it) => it.id == id);
    if (index == -1) return;

    final request = requests[index];
    final duration = DateTime.now().difference(request.startTime);
    _requests.value = [...requests]..[index] = update(request, duration);
  }
}

/// Converts [bytes] to text for display in a [NetworkRequest].
///
/// Returns `null` for empty bodies and a placeholder for binary data.
String? decodeNetworkBody(
  List<int> bytes, {
  String? contentType,
  bool isTruncated = false,
}) {
  if (bytes.isEmpty) return null;

  final isKnownText = contentType != null && _isTextContentType(contentType);
  String text;
  try {
    // `utf8` decodes ASCII compatible text, which covers most other charsets
    // used for debugging purposes as well.
    text = utf8.decode(bytes, allowMalformed: isKnownText);
  } on FormatException {
    return '<binary data, ${bytes.length} bytes>';
  }
  if (!isKnownText && contentType != null) {
    return '<binary data, ${bytes.length} bytes>';
  }
  return isTruncated ? '$text\n… (truncated)' : text;
}

bool _isTextContentType(String contentType) {
  final type = contentType.toLowerCase();
  return type.startsWith('text/') ||
      type.contains('json') ||
      type.contains('xml') ||
      type.contains('javascript') ||
      type.contains('x-www-form-urlencoded');
}
