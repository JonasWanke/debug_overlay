import 'dart:convert';
import 'dart:io';

import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:data_size/data_size.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// A dialog that shows the contents of [file] as text, an image, or a hex dump.
class const FilePreviewDialog({super.key, required final File file})
    extends StatefulWidget {
  static const _maximumBytes = 256 * 1024;
  static const _hexDumpBytes = 512;
  static const _imageExtensions = {'bmp', 'gif', 'jpeg', 'jpg', 'png', 'webp'};

  @override
  State<FilePreviewDialog> createState() => _FilePreviewDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('file', file.path));
  }
}

class _FilePreviewDialogState extends State<FilePreviewDialog> {
  late final _preview = _load();

  bool get _isImage {
    final path = widget.file.path.toLowerCase();
    final extension = path.substring(path.lastIndexOf('.') + 1);
    return FilePreviewDialog._imageExtensions.contains(extension);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _preview,
      builder: (context, snapshot) {
        final preview = snapshot.data;
        return AlertDialog(
          title: Text(_name(widget.file.path)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  SelectableText(
                    widget.file.path,
                    style: context.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  _buildContent(context, snapshot, preview),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _copy(widget.file.path),
              child: const Text('Copy path'),
            ),
            if (preview?.text != null)
              TextButton(
                onPressed: () => _copy(preview!.text!),
                child: const Text('Copy contents'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<_Preview> snapshot,
    _Preview? preview,
  ) {
    final error = snapshot.error;
    if (error != null) return Text('$error');
    if (preview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          preview.length.formatByteSize(prefix: .binary),
          style: context.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (_isImage)
          Image.file(
            widget.file,
            errorBuilder: (context, error, stackTrace) =>
                const Text('The image could not be decoded.'),
          )
        else
          SelectableText(
            preview.text ?? preview.hexDump!,
            style: context.textTheme.bodySmall!.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        if (preview.isTruncated && !_isImage) ...[
          const SizedBox(height: 8),
          Text('… (truncated)', style: context.textTheme.bodySmall),
        ],
      ],
    );
  }

  Future<_Preview> _load() async {
    final length = await widget.file.length();
    if (_isImage) return _Preview(length: length);

    final handle = await widget.file.open();
    final List<int> bytes;
    try {
      bytes = await handle.read(FilePreviewDialog._maximumBytes);
    } finally {
      await handle.close();
    }
    final isTruncated = length > bytes.length;

    // A truncated read may end within a multi-byte character.
    final String text;
    try {
      text = utf8.decode(bytes, allowMalformed: isTruncated);
    } on FormatException {
      return _binary(length, bytes);
    }
    if (bytes.contains(0)) return _binary(length, bytes);

    return _Preview(
      length: length,
      text: isTruncated ? text : _prettyPrintJson(text),
      isTruncated: isTruncated,
    );
  }

  _Preview _binary(int length, List<int> bytes) {
    return _Preview(
      length: length,
      hexDump: _hexDump(bytes.take(FilePreviewDialog._hexDumpBytes).toList()),
      isTruncated: length > FilePreviewDialog._hexDumpBytes,
    );
  }

  String _prettyPrintJson(String text) {
    if (!widget.file.path.toLowerCase().endsWith('.json')) return text;

    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(text));
    } on FormatException {
      return text;
    }
  }

  String _hexDump(List<int> bytes) {
    final lines = <String>[];
    for (var offset = 0; offset < bytes.length; offset += 16) {
      final chunk = bytes.skip(offset).take(16).toList();
      final hex = chunk
          .map((it) => it.toRadixString(16).padLeft(2, '0'))
          .join(' ')
          .padRight(16 * 3 - 1);
      final ascii = String.fromCharCodes(
        chunk.map((it) => it >= 0x20 && it < 0x7f ? it : 0x2e),
      );
      lines.add('${offset.toRadixString(16).padLeft(6, '0')}  $hex  $ascii');
    }
    return lines.join('\n');
  }

  Future<void> _copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('preview', _preview));
  }
}

class const _Preview({
  required final int length,

  /// The decoded contents or `null` for binary files and images.
  final String? text,

  /// A hex dump of the start of binary files.
  final String? hexDump,
  final bool isTruncated = false,
});

String _name(String path) =>
    path.substring(path.lastIndexOf(Platform.pathSeparator) + 1);
