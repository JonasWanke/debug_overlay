import 'package:debug_overlay/debug_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int start(NetworkRequestCollection requests, [String path = '']) =>
      requests.start(method: 'get', url: Uri.parse('https://example.com$path'));

  group('NetworkRequestCollection', () {
    test('start records an in-flight request with an upper-case method', () {
      final requests = NetworkRequestCollection();
      final id = start(requests);

      final request = requests.requests.single;
      expect(request.id, id);
      expect(request.method, 'GET');
      expect(request.isInFlight, isTrue);
      expect(request.hasFailed, isFalse);
    });

    test('complete adds the response', () {
      final requests = NetworkRequestCollection();
      final id = start(requests);

      requests.complete(id, statusCode: 404, responseBody: 'Not found');

      final request = requests.requests.single;
      expect(request.isInFlight, isFalse);
      expect(request.statusCode, 404);
      expect(request.responseBody, 'Not found');
    });

    test('fail records the error', () {
      final requests = NetworkRequestCollection();
      final id = start(requests);

      requests.fail(id, 'Timeout');

      final request = requests.requests.single;
      expect(request.isInFlight, isFalse);
      expect(request.hasFailed, isTrue);
      expect(request.error, 'Timeout');
    });

    test('only updates the matching request', () {
      final requests = NetworkRequestCollection();
      final first = start(requests, '/1');
      start(requests, '/2');

      requests.complete(first, statusCode: 200);

      expect(requests.requests[0].statusCode, 200);
      expect(requests.requests[1].isInFlight, isTrue);
    });

    test('ignores updates for evicted requests', () {
      final requests = NetworkRequestCollection(maximumSize: 1);
      final first = start(requests, '/1');
      start(requests, '/2');

      requests.complete(first, statusCode: 200);

      expect(requests.requests.single.url.path, '/2');
      expect(requests.requests.single.isInFlight, isTrue);
    });

    test('evicts the oldest request when exceeding maximumSize', () {
      final requests = NetworkRequestCollection(maximumSize: 2);
      for (final path in ['/1', '/2', '/3']) {
        start(requests, path);
      }

      expect(requests.requests.map((it) => it.url.path), ['/2', '/3']);
    });

    test('maximumSize setter trims requests', () {
      final requests = NetworkRequestCollection();
      for (final path in ['/1', '/2', '/3']) {
        start(requests, path);
      }

      requests.maximumSize = 1;

      expect(requests.maximumSize, 1);
      expect(requests.requests.single.url.path, '/3');
    });

    test('clear removes all requests', () {
      final requests = NetworkRequestCollection();
      start(requests);

      requests.clear();

      expect(requests.requests, isEmpty);
    });
  });

  group('decodeNetworkBody', () {
    test('returns null for empty bodies', () {
      expect(decodeNetworkBody([]), isNull);
    });

    test('decodes text without a content type', () {
      expect(decodeNetworkBody([104, 105]), 'hi');
    });

    test('decodes known text content types', () {
      expect(
        decodeNetworkBody([123, 125], contentType: 'application/json'),
        '{}',
      );
    });

    test('returns a placeholder for unknown content types', () {
      expect(
        decodeNetworkBody([1, 2, 3], contentType: 'image/png'),
        '<binary data, 3 bytes>',
      );
    });

    test('returns a placeholder for invalid UTF-8', () {
      expect(decodeNetworkBody([0xff, 0xfe]), '<binary data, 2 bytes>');
    });

    test('marks truncated bodies', () {
      expect(
        decodeNetworkBody([104, 105], isTruncated: true),
        'hi\n… (truncated)',
      );
    });
  });
}
