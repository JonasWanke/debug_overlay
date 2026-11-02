import 'dart:convert';

import 'package:debug_overlay/debug_overlay.dart';
import 'package:dio/dio.dart';

/// An [Interceptor] that records all requests and responses in a
/// [NetworkRequestCollection].
///
/// Add it after interceptors that modify requests or responses, so that it
/// records what is actually sent and received:
///
/// ```dart
/// dio.interceptors.add(DebugDioInterceptor(networkRequests));
/// ```
class DebugDioInterceptor(
  this.requests, {

  /// The maximum number of characters of each request and response body that
  /// are stored; longer bodies are truncated in the log (but not on the wire).
  final int maximumBodyLength = 1024 * 1024,
}) extends Interceptor {
  static const _idKey = 'debug_overlay.requestId';

  final NetworkRequestCollection requests;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_idKey] = requests.start(
      method: options.method,
      url: options.uri,
      requestHeaders: _flattenRequestHeaders(options.headers),
      requestBody: _describeBody(
        options.data,
        contentType: options.headers[Headers.contentTypeHeader]?.toString(),
      ),
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _complete(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      // E.g., a status code rejected by `validateStatus`.
      _complete(response);
    } else {
      final id = err.requestOptions.extra[_idKey];
      if (id is int) requests.fail(id, err, err.stackTrace);
    }
    handler.next(err);
  }

  void _complete(Response<dynamic> response) {
    final id = response.requestOptions.extra[_idKey];
    if (id is! int) return;

    requests.complete(
      id,
      statusCode: response.statusCode ?? 0,
      reasonPhrase: response.statusMessage,
      responseHeaders: {
        for (final entry in response.headers.map.entries)
          entry.key: entry.value.join(', '),
      },
      responseBody: _describeBody(
        response.data,
        contentType: response.headers.value(Headers.contentTypeHeader),
      ),
    );
  }

  Map<String, String> _flattenRequestHeaders(Map<String, dynamic> headers) {
    return {
      for (final entry in headers.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };
  }

  String? _describeBody(Object? data, {String? contentType}) {
    return switch (data) {
      null => null,
      String() => _truncate(data),
      List<int>() => decodeNetworkBody(
        data.length > maximumBodyLength
            ? data.sublist(0, maximumBodyLength)
            : data,
        contentType: contentType,
        isTruncated: data.length > maximumBodyLength,
      ),
      FormData() => [
        for (final field in data.fields) '${field.key}: ${field.value}',
        for (final file in data.files)
          // ignore: lines_longer_than_80_chars
          '${file.key}: <file ${file.value.filename ?? ''}, ${file.value.length} bytes>',
      ].join('\n'),
      Stream<Object?>() || ResponseBody() => '<streamed body>',
      _ => _truncate(_encodeObject(data)),
    };
  }

  String _encodeObject(Object data) {
    try {
      return jsonEncode(data);
    } on Object {
      return data.toString();
    }
  }

  String _truncate(String text) {
    return text.length > maximumBodyLength
        ? '${text.substring(0, maximumBodyLength)}\n... (truncated)'
        : text;
  }
}
