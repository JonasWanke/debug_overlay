import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A top-level directory in the `FileBrowserDebugHelper`.
@immutable
class const FileBrowserRoot({
  /// The label shown in the list of roots.
  required final String name,
  required final Directory directory,
}) with Diagnosticable {
  /// Loads the directories that are available on the current platform.
  ///
  /// Directories with the same path are only included once.
  static Future<List<FileBrowserRoot>> loadDefaults() async {
    if (kIsWeb) return [];

    final candidates = await [
      _load('Documents', getApplicationDocumentsDirectory),
      _load('Application Support', getApplicationSupportDirectory),
      _load('Library', getLibraryDirectory),
      _load('Temporary', getTemporaryDirectory),
      _load('Cache', getApplicationCacheDirectory),
      _load('External Storage', getExternalStorageDirectory),
      _loadAll('External Cache', getExternalCacheDirectories),
    ].wait;

    final seenPaths = <String>{};
    return [
      for (final root in candidates.expand((it) => it))
        if (seenPaths.add(root.directory.path)) root,
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('name', name))
      ..add(StringProperty('directory', directory.path));
  }
}

Future<List<FileBrowserRoot>> _load(
  String name,
  AsyncValueGetter<Directory?> load,
) {
  return _loadAll(name, () async {
    final directory = await load();
    return directory == null ? null : [directory];
  });
}

Future<List<FileBrowserRoot>> _loadAll(
  String name,
  AsyncValueGetter<List<Directory>?> load,
) async {
  // Unsupported directories throw, e.g., an `UnsupportedError` or a
  // `MissingPlatformDirectoryException`.
  try {
    final directories = await load();
    if (directories == null) return [];

    return [
      for (final (index, directory) in directories.indexed)
        FileBrowserRoot(
          name: directories.length == 1 ? name : '$name ${index + 1}',
          directory: directory,
        ),
    ];
  } on Object {
    return [];
  }
}
