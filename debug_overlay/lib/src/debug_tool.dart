import 'package:material_ui/material_ui.dart';

import 'debug_overlay.dart';
import 'debug_tool_action.dart';

/// An entry in the tool picker of the expanded [DebugOverlay].
///
/// Register tools via [DebugOverlay.tools], [DebugOverlay.prependTool], or
/// [DebugOverlay.appendTool].
///
/// A tool is a long-lived object that owns its state, so filters and similar
/// settings survive switching to another tool or closing the overlay. After
/// changing state that affects [buildActions] or [buildSliver], call
/// [notifyListeners] to rebuild the overlay.
///
/// The overlay never disposes tools. If you create tools dynamically, dispose
/// them yourself after removing them from [DebugOverlay.tools].
abstract class DebugTool({
  /// The icon shown in the header and the tool picker.
  required final IconData icon,

  /// A short name that is shown in the header and the tool picker.
  required final String title,
}) extends ChangeNotifier {
  /// Actions shown in the header of the overlay, next to [title].
  ///
  /// Put the most important actions first; the last ones move into an overflow
  /// menu if the header is too narrow.
  List<DebugToolAction> buildActions(BuildContext context) => const [];

  /// The content of the tool, which has to be a sliver.
  Widget buildSliver(BuildContext context);

  // Search

  /// Whether the header offers a search field for this tool.
  ///
  /// If `true`, [buildSliver] should only show entries for which
  /// [matchesSearch] returns `true`.
  bool get isSearchable => false;

  /// Whether the search field is shown in the header.
  ///
  /// Hiding it also clears [searchQuery].
  bool get isSearchOpen => _isSearchOpen;
  var _isSearchOpen = false;
  set isSearchOpen(bool value) {
    assert(isSearchable);
    if (value == _isSearchOpen) return;

    _isSearchOpen = value;
    if (!value) _searchQuery = '';
    notifyListeners();
  }

  /// The text entered into the search field; empty if there is no filter.
  String get searchQuery => _searchQuery;
  var _searchQuery = '';
  var _searchTerms = <String>{};

  /// Updates [searchQuery] and rebuilds the content.
  set searchQuery(String query) {
    if (query == _searchQuery) return;

    _searchQuery = query;
    _searchTerms = query.trim().toLowerCase().split(RegExp(r'\s+')).toSet();
    notifyListeners();
  }

  /// Whether [texts] contains [searchQuery]'s terms, ignoring case.
  ///
  /// Always `true` if the query is empty.
  bool matchesSearch(List<String> texts) {
    if (_searchTerms.isEmpty) return true;

    final lowerCaseTexts = texts.map((it) => it.toLowerCase()).toList();
    return _searchTerms.every(
      (term) => lowerCaseTexts.any((text) => text.contains(term)),
    );
  }
}
