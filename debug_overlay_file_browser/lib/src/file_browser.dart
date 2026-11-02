import 'dart:async';
import 'dart:io';

import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:data_size/data_size.dart';
import 'package:debug_overlay/debug_overlay.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'file_preview.dart';
import 'roots.dart';

/// A [DebugHelper] that lists the files and directories of the app's private
/// storage areas.
///
/// Files can be previewed as text, image, or hex dump. Entries can be deleted
/// after confirming a dialog. This is not available on the web.
class const FileBrowserDebugHelper({
  super.key,
  final List<FileBrowserRoot>? roots,
}) extends StatefulWidget {
  /// Creates a [DebugTool] for this helper.
  ///
  /// If [roots] is `null`, the directories provided by `path_provider` that are
  /// available on the current platform are used.
  static DebugTool tool({List<FileBrowserRoot>? roots}) {
    return DebugTool(
      icon: Icons.folder_open,
      title: 'Files',
      sliver: FileBrowserDebugHelper(roots: roots),
    );
  }

  @override
  State<FileBrowserDebugHelper> createState() => _FileBrowserDebugHelperState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty('roots', roots));
  }
}

class _FileBrowserDebugHelperState extends State<FileBrowserDebugHelper> {
  late final _roots = widget.roots != null
      ? Future.value(widget.roots)
      : FileBrowserRoot.loadDefaults();

  /// The directory being shown or `null` for the list of roots.
  Directory? _directory;
  late var _entries = Future.value(<_Entry>[]);
  Future<int>? _size;

  @override
  Widget build(BuildContext context) {
    return DebugHelper(
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
      contentPadding: EdgeInsets.zero,
      sliver: FutureBuilder(
        future: _roots,
        builder: (context, snapshot) {
          final roots = snapshot.data;
          if (roots == null) {
            return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (roots.isEmpty) {
            return SliverToBoxAdapter(
              child: Center(
                child: Text(
                  'No directories available on this platform.',
                  style: context.textTheme.bodySmall,
                ),
              ),
            );
          }

          final directory = _directory;
          return directory == null
              ? _buildRoots(roots)
              : _buildDirectory(directory, roots);
        },
      ),
    );
  }

  Widget _buildRoots(List<FileBrowserRoot> roots) {
    return SliverList.builder(
      itemCount: roots.length,
      itemBuilder: (context, index) {
        final root = roots[index];
        return ListTile(
          leading: const Icon(Icons.folder_special_outlined),
          title: Text(root.name),
          subtitle: Text(root.directory.path),
          onTap: () => _open(root.directory),
        );
      },
    );
  }

  Widget _buildDirectory(Directory directory, List<FileBrowserRoot> roots) {
    return FutureBuilder(
      future: _entries,
      builder: (context, snapshot) {
        final entries = snapshot.data;
        return SliverList.list(
          children: [
            _buildHeader(directory, entries?.length),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('..'),
              onTap: () => _up(directory, roots),
            ),
            if (snapshot.error case final error?)
              Padding(padding: const .all(16), child: Text('$error'))
            else if (entries == null)
              const Center(child: CircularProgressIndicator())
            else if (entries.isEmpty)
              Padding(
                padding: const .all(16),
                child: Text('Empty.', style: context.textTheme.bodySmall),
              )
            else
              for (final entry in entries)
                _EntryTile(
                  key: ValueKey(entry.entity.path),
                  entry: entry,
                  onTap: () => _onTap(entry),
                  onDelete: () => _confirmDelete(entry),
                ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(Directory directory, int? itemCount) {
    return Padding(
      padding: const .fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          SelectableText(directory.path, style: context.textTheme.bodySmall),
          Row(
            children: [
              if (itemCount != null)
                Text('$itemCount items', style: context.textTheme.bodySmall),
              const Spacer(),
              _buildSize(directory),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSize(Directory directory) {
    final size = _size;
    if (size == null) {
      return TextButton(
        onPressed: () =>
            setState(() => unawaited(_size = _computeSize(directory))),
        child: const Text('Calculate size'),
      );
    }

    return FutureBuilder(
      future: size,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        return Text(
          bytes == null
              ? 'Calculating…'
              : 'Total: ${bytes.formatByteSize(prefix: .binary)}',
          style: context.textTheme.bodySmall,
        );
      },
    );
  }

  void _open(Directory directory) {
    setState(() {
      _directory = directory;
      _entries = _list(directory);
      _size = null;
    });
  }

  void _up(Directory directory, List<FileBrowserRoot> roots) {
    final isRoot = roots.any((it) => it.directory.path == directory.path);
    if (isRoot) {
      setState(() => _directory = null);
    } else {
      _open(directory.parent);
    }
  }

  void _refresh() {
    final directory = _directory;
    if (directory != null) _open(directory);
  }

  Future<void> _onTap(_Entry entry) async {
    final entity = entry.entity;
    if (entity is Directory) {
      _open(entity);
    } else if (entity is File) {
      await showDialog<void>(
        context: context,
        builder: (context) => FilePreviewDialog(file: entity),
      );
    }
  }

  Future<void> _confirmDelete(_Entry entry) async {
    final entity = entry.entity;
    final isDirectory = entity is Directory;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${isDirectory ? 'directory' : 'file'}?'),
        content: Text(
          '${entity.path}\n\n'
          '${isDirectory ? 'This also deletes everything inside it. ' : ''}'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await entity.delete(recursive: true);
    } on FileSystemException catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Could not delete'),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
    if (!mounted) return;
    _refresh();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('directory', _directory?.path));
  }
}

Future<List<_Entry>> _list(Directory directory) async {
  // Symbolic links are listed but not followed.
  final entities = await directory.list(followLinks: false).toList();
  // Async, so that large directories don't block the UI.
  final entries = await Future.wait(
    // ignore: avoid_slow_async_io
    entities.map((it) async => _Entry(it, await it.stat())),
  );
  return entries..sort((a, b) {
    final aIsDirectory = a.entity is Directory;
    if (aIsDirectory != (b.entity is Directory)) return aIsDirectory ? -1 : 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
}

Future<int> _computeSize(Directory directory) async {
  var total = 0;
  // Unreadable subdirectories are skipped.
  final entities = directory
      .list(recursive: true, followLinks: false)
      .handleError((Object _) {}, test: (it) => it is FileSystemException);
  await for (final entity in entities) {
    if (entity is! File) continue;

    try {
      total += await entity.length();
    } on FileSystemException {
      // The file vanished or is unreadable.
    }
  }
  return total;
}

class const _Entry(final FileSystemEntity entity, final FileStat stat) {
  String get name {
    final path = entity.path;
    return path.substring(path.lastIndexOf(Platform.pathSeparator) + 1);
  }
}

class const _EntryTile({
  super.key,
  required final _Entry entry,
  required final VoidCallback onTap,
  required final VoidCallback onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entity = entry.entity;
    final isFile = entity is File;
    final modified = entry.stat.modified.toString().split('.').first;
    return ListTile(
      leading: Icon(switch (entity) {
        Directory() => Icons.folder_outlined,
        Link() => Icons.link,
        _ => Icons.insert_drive_file_outlined,
      }),
      title: Text(entry.name),
      subtitle: Text(
        [
          if (isFile) entry.stat.size.formatByteSize(prefix: .binary),
          if (entity is Link) 'Symbolic link',
          modified,
        ].join(' · '),
      ),
      onTap: entity is Link ? null : onTap,
      trailing: PopupMenuButton<VoidCallback>(
        onSelected: (it) => it(),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: () => Clipboard.setData(ClipboardData(text: entity.path)),
            child: const Text('Copy path'),
          ),
          PopupMenuItem(value: onDelete, child: const Text('Delete')),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('path', entry.entity.path))
      ..add(ObjectFlagProperty.has('onTap', onTap))
      ..add(ObjectFlagProperty.has('onDelete', onDelete));
  }
}
