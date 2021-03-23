import 'package:flutter/material.dart';

class DebugOverlay extends StatelessWidget {
  const DebugOverlay({required this.modules});

  final List<Widget> modules;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: modules.length,
      itemBuilder: (context, index) => modules[index],
      separatorBuilder: (context, index) => SizedBox(height: 16),
    );
  }
}
