import 'package:debug_overlay/debug_overlay.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🐛 debug_overlay example',
      builder: DebugOverlay.builder(showOnShake: false),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🐛 debug_overlay example')),
      body: Center(
        child: ElevatedButton(
          onPressed: DebugOverlay.show,
          child: Text('Show Debug Overlay'),
        ),
      ),
    );
  }
}
