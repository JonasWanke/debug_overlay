import 'dart:async';

import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:debug_overlay/debug_overlay.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [DebugHelper] that lists all entries of [SharedPreferencesAsync] and
/// allows to add, edit, and delete them.
///
/// Entries written by the legacy `SharedPreferences` API use a `flutter.`
/// prefix on some platforms and are only visible here if they're stored in the
/// same location as the one used by [SharedPreferencesAsync].
class const SharedPreferencesDebugHelper({
  super.key,
  final SharedPreferencesAsync? preferences,
}) extends StatefulWidget {
  /// Creates a [DebugTool] for this helper.
  ///
  /// If [preferences] is `null`, a default [SharedPreferencesAsync] is used.
  static DebugTool tool({SharedPreferencesAsync? preferences}) {
    return DebugTool(
      icon: Icons.storage,
      title: 'Shared Preferences',
      sliver: SharedPreferencesDebugHelper(preferences: preferences),
    );
  }

  @override
  State<SharedPreferencesDebugHelper> createState() =>
      _SharedPreferencesDebugHelperState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('preferences', preferences));
  }
}

class _SharedPreferencesDebugHelperState
    extends State<SharedPreferencesDebugHelper> {
  late final _preferences = widget.preferences ?? SharedPreferencesAsync();
  late var _entries = _loadEntries();

  @override
  Widget build(BuildContext context) {
    return DebugHelper(
      actions: [
        IconButton(
          tooltip: 'Add entry',
          onPressed: () => _showEditor(context),
          icon: const Icon(Icons.add),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
      contentPadding: .zero,
      sliver: FutureBuilder(
        future: _entries,
        builder: (context, snapshot) {
          final error = snapshot.error;
          if (error != null) {
            return SliverToBoxAdapter(
              child: Center(child: Text('$error\n${snapshot.stackTrace!}')),
            );
          }

          final entries = snapshot.data;
          if (entries == null) {
            return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (entries.isEmpty) {
            return SliverToBoxAdapter(
              child: Center(
                child: Text(
                  'No entries available.',
                  style: context.textTheme.bodySmall,
                ),
              ),
            );
          }

          return SliverList.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _EntryTile(
                key: ValueKey(entry.key),
                entry: entry,
                onEdit: () => _showEditor(context, entry),
                onDelete: () => _delete(entry.key),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<MapEntry<String, Object?>>> _loadEntries() async {
    final all = await _preferences.getAll();
    return all.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  }

  void _refresh() => setState(() => unawaited(_entries = _loadEntries()));

  Future<void> _showEditor(
    BuildContext context, [
    MapEntry<String, Object?>? entry,
  ]) async {
    final result = await showDialog<({String key, Object value})>(
      context: context,
      builder: (context) =>
          _EntryDialog(existingKey: entry?.key, existingValue: entry?.value),
    );
    if (result == null) return;

    await _write(result.key, result.value);
    if (!mounted) return;
    _refresh();
  }

  Future<void> _write(String key, Object value) => switch (value) {
    bool() => _preferences.setBool(key, value),
    int() => _preferences.setInt(key, value),
    double() => _preferences.setDouble(key, value),
    String() => _preferences.setString(key, value),
    List<String>() => _preferences.setStringList(key, value),
    _ => throw ArgumentError.value(value, 'value', 'Unsupported type'),
  };

  Future<void> _delete(String key) async {
    await _preferences.remove(key);
    if (!mounted) return;
    _refresh();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('preferences', _preferences));
  }
}

class const _EntryTile({
  super.key,
  required final MapEntry<String, Object?> entry,
  required final VoidCallback onEdit,
  required final VoidCallback onDelete,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final type = _PreferenceType.of(entry.value);
    return ListTile(
      title: Text(entry.key),
      subtitle: Text(
        '${type?.label ?? entry.value.runtimeType}: '
        '${_valueToText(entry.value)}',
      ),
      onTap: onEdit,
      trailing: IconButton(
        tooltip: 'Delete',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outlined),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('entry', entry))
      ..add(ObjectFlagProperty.has('onEdit', onEdit))
      ..add(ObjectFlagProperty.has('onDelete', onDelete));
  }
}

/// A dialog for adding a new entry (if [existingKey] is `null`) or editing the
/// value of an existing one.
///
/// Pops with the new key and value or `null` if cancelled.
class const _EntryDialog({
  final String? existingKey,
  final Object? existingValue,
}) extends StatefulWidget {
  @override
  State<_EntryDialog> createState() => _EntryDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('existingKey', existingKey))
      ..add(DiagnosticsProperty('existingValue', existingValue));
  }
}

class _EntryDialogState extends State<_EntryDialog> {
  late final _keyController = TextEditingController(text: widget.existingKey);
  late final _valueController = TextEditingController(
    text: widget.existingValue is bool
        ? ''
        : widget.existingValue == null
        ? null
        : _valueToText(widget.existingValue, separator: '\n'),
  );
  late var _type = _PreferenceType.of(widget.existingValue) ?? .string;
  late var _bool = widget.existingValue == true;

  bool get _isNew => widget.existingKey == null;

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _parseValue();
    return AlertDialog(
      title: Text(_isNew ? 'Add entry' : 'Edit entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            TextField(
              controller: _keyController,
              enabled: _isNew,
              decoration: const InputDecoration(labelText: 'Key'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (_isNew)
              DropdownButton(
                value: _type,
                isExpanded: true,
                onChanged: (type) => setState(() => _type = type!),
                items: [
                  for (final type in _PreferenceType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
              ),
            _buildValueEditor(value),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _keyController.text.isEmpty || value == null
              ? null
              : () =>
                    Navigator.of(context)
                        .pop((key: _keyController.text, value: value)),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildValueEditor(Object? parsedValue) {
    if (_type == .boolean) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Value'),
        value: _bool,
        onChanged: (value) => setState(() => _bool = value),
      );
    }

    return TextField(
      controller: _valueController,
      keyboardType: switch (_type) {
        .integer => const TextInputType.numberWithOptions(signed: true),
        .decimal => const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        _ => TextInputType.multiline,
      },
      minLines: _type == .string || _type == .stringList ? 1 : null,
      maxLines: _type == .string || _type == .stringList ? 8 : 1,
      decoration: InputDecoration(
        labelText: 'Value',
        helperText: _type == .stringList ? 'One item per line' : null,
        errorText: parsedValue == null ? 'Invalid ${_type.label}' : null,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  /// Returns the entered value or `null` if it's invalid.
  Object? _parseValue() {
    final text = _valueController.text;
    return switch (_type) {
      .boolean => _bool,
      .integer => int.tryParse(text.trim()),
      .decimal => double.tryParse(text.trim()),
      .string => text,
      .stringList => text.isEmpty ? <String>[] : text.split('\n'),
    };
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty('type', _type))
      ..add(DiagnosticsProperty('bool', _bool));
  }
}

enum _PreferenceType(final String label) {
  boolean('bool'),
  integer('int'),
  decimal('double'),
  string('String'),
  stringList('List<String>');

  static _PreferenceType? of(Object? value) => switch (value) {
    bool() => .boolean,
    int() => .integer,
    double() => .decimal,
    String() => .string,
    List() => .stringList,
    _ => null,
  };
}

String _valueToText(Object? value, {String separator = ', '}) {
  if (value is List) return value.join(separator);
  return '$value';
}
