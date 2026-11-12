import 'dart:math';

import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'debug_tool.dart';

/// The pinned header of the expanded overlay.
///
/// It shows the active tool's icon and title as a button that opens a grid of
/// all tools, followed by the tool's [actions] and an optional collapse button.
class const DebugOverlayHeader({
  super.key,
  required final List<DebugTool> tools,
  required final int? selectedIndex,
  required final ValueChanged<int> onSelected,
  required final List<Widget> actions,
  final VoidCallback? onCollapse,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewPadding = context.mediaQuery.viewPadding;
    final selectedTool = selectedIndex == null ? null : tools[selectedIndex!];
    final searchTool = selectedTool != null && selectedTool.isSearchable
        ? selectedTool
        : null;
    // Sliver content is painted over the header's shadow, so we use a
    // different background color and a divider to separate it from the
    // content below.
    return Material(
      color: context.theme.colorScheme.surfaceContainerHigh,
      child: Column(
        mainAxisSize: .min,
        children: [
          Padding(
            padding: .fromLTRB(
              viewPadding.left + 8,
              viewPadding.top + 4,
              viewPadding.right + 8,
              4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: selectedIndex == null
                        ? const SizedBox.shrink()
                        : _ToolPicker(
                            tools: tools,
                            selectedIndex: selectedIndex!,
                            onSelected: onSelected,
                          ),
                  ),
                ),
                ...actions,
                if (searchTool != null)
                  (searchTool.isSearchOpen
                      ? IconButton.filledTonal
                      : IconButton.new)(
                    icon: const Icon(Icons.search),
                    tooltip: searchTool.isSearchOpen
                        ? 'Close search'
                        : 'Search',
                    onPressed: () =>
                        searchTool.isSearchOpen = !searchTool.isSearchOpen,
                  ),
                if (onCollapse != null)
                  IconButton(
                    icon: const Icon(Icons.close_fullscreen),
                    tooltip: 'Collapse',
                    onPressed: onCollapse,
                  ),
              ],
            ),
          ),
          if (searchTool != null && searchTool.isSearchOpen)
            _SearchField(
              // A new field per tool, so the text isn't carried over.
              key: ObjectKey(searchTool),
              tool: searchTool,
              padding: .fromLTRB(
                viewPadding.left + 16,
                0,
                viewPadding.right + 16,
                8,
              ),
            ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty('tools', tools))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(ObjectFlagProperty.has('onSelected', onSelected))
      ..add(IterableProperty('actions', actions))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onCollapse', onCollapse));
  }
}

class const _SearchField({
  super.key,
  required final DebugTool tool,
  required final EdgeInsets padding,
}) extends StatefulWidget {
  @override
  State<_SearchField> createState() => _SearchFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('tool', tool))
      ..add(DiagnosticsProperty('padding', padding));
  }
}

class _SearchFieldState extends State<_SearchField> {
  late final _controller = TextEditingController(text: widget.tool.searchQuery);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: .search,
        onChanged: (it) => widget.tool.searchQuery = it,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _controller.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      widget.tool.searchQuery = '';
                    },
                  ),
          ),
          border: const OutlineInputBorder(borderRadius: .all(.circular(24))),
        ),
      ),
    );
  }
}

class const _ToolPicker({
  required final List<DebugTool> tools,
  required final int selectedIndex,
  required final ValueChanged<int> onSelected,
}) extends StatefulWidget {
  @override
  State<_ToolPicker> createState() => _ToolPickerState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty('tools', tools))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(ObjectFlagProperty.has('onSelected', onSelected));
  }
}

class _ToolPickerState extends State<_ToolPicker> {
  final _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    final tool = widget.tools[widget.selectedIndex];
    return MenuAnchor(
      controller: _controller,
      style: const MenuStyle(padding: WidgetStatePropertyAll(.all(8))),
      menuChildren: [
        _ToolGrid(
          tools: widget.tools,
          selectedIndex: widget.selectedIndex,
          onSelected: (index) {
            _controller.close();
            widget.onSelected(index);
          },
        ),
      ],
      builder: (context, controller, _) => TextButton(
        style: TextButton.styleFrom(
          foregroundColor: context.theme.colorScheme.onSurface,
          textStyle: context.textTheme.titleMedium,
        ),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        child: Row(
          mainAxisSize: .min,
          children: [
            Icon(tool.icon),
            const SizedBox(width: 8),
            Flexible(child: Text(tool.title, overflow: .ellipsis)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class const _ToolGrid({
  required final List<DebugTool> tools,
  required final int selectedIndex,
  required final ValueChanged<int> onSelected,
}) extends StatelessWidget {
  static const _maxColumns = 4;

  @override
  Widget build(BuildContext context) {
    // Leave some room next to the menu on narrow screens.
    final fittingColumns =
        (context.mediaQuery.size.width - 32) ~/ _ToolTile.width;
    final columns = min(tools.length, fittingColumns.clamp(1, _maxColumns));

    return SizedBox(
      width: columns * _ToolTile.width,
      child: Wrap(
        children: [
          for (final (index, tool) in tools.indexed)
            _ToolTile(
              tool: tool,
              isSelected: index == selectedIndex,
              onTap: () => onSelected(index),
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty('tools', tools))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(ObjectFlagProperty.has('onSelected', onSelected));
  }
}

class const _ToolTile({
  required final DebugTool tool,
  required final bool isSelected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  static const width = 88.0;
  static const _height = 72.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _height,
      child: Padding(
        padding: const .all(2),
        child: Material(
          color: isSelected
              ? context.theme.colorScheme.secondaryContainer
              : Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: .all(.circular(12)),
          ),
          clipBehavior: .antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: .center,
              children: [
                Icon(tool.icon),
                const SizedBox(height: 4),
                Padding(
                  padding: const .symmetric(horizontal: 4),
                  child: Text(
                    tool.title,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: context.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('tool', tool))
      ..add(FlagProperty('isSelected', value: isSelected))
      ..add(ObjectFlagProperty.has('onTap', onTap));
  }
}
