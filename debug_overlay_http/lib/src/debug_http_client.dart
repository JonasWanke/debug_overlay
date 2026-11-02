import 'dart:async';
import 'dart:typed_data';

import 'package:debug_overlay/debug_overlay.dart';
import 'package:http/http.dart';

/// A [Client] that records all requests and responses in a
/// [NetworkRequestCollection].
///
/// Response bodies are copied while they stream through, so callers receive
/// the unmodified response.
class DebugHttpClient(
  this.requests, {

  /// The client that actually sends the requests, defaults to [Client.new].
  Client? inner,

  /// The maximum number of bytes of each request and response body that are
  /// stored; longer bodies are truncated in the log (but not on the wire).
  final int maximumBodyBytes = 1024 * 1024,
}) extends BaseClient {
  this : _inner = inner ?? Client();

  final NetworkRequestCollection requests;
  final Client _inner;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final id = requests.start(
      method: request.method,
      url: request.url,
      requestHeaders: Map.of(request.headers),
      requestBody: _describeBody(request),
    );

    final StreamedResponse response;
    try {
      response = await _inner.send(request);
    } catch (err, st) {
      requests.fail(id, err, st);
      rethrow;
    }

    final stream = _recordResponse(id, response);
    return StreamedResponse(
      stream,
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }

  /// Describes the body without consuming it.
  String? _describeBody(BaseRequest request) {
    if (request is Request) {
      return decodeNetworkBody(
        request.bodyBytes.length > maximumBodyBytes
            ? request.bodyBytes.sublist(0, maximumBodyBytes)
            : request.bodyBytes,
        contentType: request.headers['content-type'],
        isTruncated: request.bodyBytes.length > maximumBodyBytes,
      );
    }
    if (request is MultipartRequest) {
      return [
        for (final entry in request.fields.entries)
          '${entry.key}: ${entry.value}',
        for (final file in request.files)
          '${file.field}: <file ${file.filename ?? ''}, ${file.length} bytes>',
      ].join('\n');
    }
    return request.contentLength == 0 ? null : '<streamed body>';
  }

  /// Forwards all chunks of [response] unchanged while copying them, and
  /// records the response once the stream ends or is cancelled.
  Stream<List<int>> _recordResponse(int id, StreamedResponse response) async* {
    final bytes = BytesBuilder();
    var isTruncated = false;
    var hasFailed = false;
    try {
      await for (final chunk in response.stream) {
        final remaining = maximumBodyBytes - bytes.length;
        if (chunk.length <= remaining) {
          bytes.add(chunk);
        } else {
          if (remaining > 0) bytes.add(chunk.sublist(0, remaining));
          isTruncated = true;
        }
        yield chunk;
      }
    } catch (err, st) {
      hasFailed = true;
      requests.fail(id, err, st);
      rethrow;
    } finally {
      if (!hasFailed) {
        requests.complete(
          id,
          statusCode: response.statusCode,
          reasonPhrase: response.reasonPhrase,
          responseHeaders: response.headers,
          responseBody: decodeNetworkBody(
            bytes.takeBytes(),
            contentType: response.headers['content-type'],
            isTruncated: isTruncated,
          ),
        );
      }
    }
  }
}
