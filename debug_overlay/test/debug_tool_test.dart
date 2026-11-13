import 'package:debug_overlay/debug_overlay.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestTool() extends DebugTool {
  this : super(icon: const IconData(0), title: 'Test');

  @override
  bool get isSearchable => true;

  @override
  Widget buildSliver(BuildContext context) => const SliverToBoxAdapter();
}

void main() {
  group('DebugTool search', () {
    test('matches everything without a query', () {
      expect(_TestTool().matchesSearch(['anything']), isTrue);
    });

    test('matches terms case-insensitively in any text', () {
      final tool = _TestTool()..searchQuery = 'FOO bar';

      expect(tool.matchesSearch(['a foo', 'BAR b']), isTrue);
      expect(tool.matchesSearch(['foo']), isFalse);
    });

    test('a blank query matches everything', () {
      final tool = _TestTool()..searchQuery = '  ';

      expect(tool.matchesSearch(['anything']), isTrue);
    });

    test('closing the search clears the filter', () {
      final tool = _TestTool()
        ..isSearchOpen = true
        ..searchQuery = 'foo';
      expect(tool.matchesSearch(['bar']), isFalse);

      tool.isSearchOpen = false;

      expect(tool.searchQuery, isEmpty);
      expect(tool.matchesSearch(['bar']), isTrue);
    });

    test('notifies listeners only on changes', () {
      var notifications = 0;
      final tool = _TestTool()..addListener(() => notifications++);

      tool
        ..searchQuery = 'foo'
        ..searchQuery = 'foo';
      expect(notifications, 1);

      tool
        ..isSearchOpen = true
        ..isSearchOpen = true;
      expect(notifications, 2);
    });
  });
}
