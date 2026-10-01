import 'package:demo_core/demo_core.dart';
import 'package:flutter/material.dart';

import 'pages/pages.dart';

void main() {
  runApp(
    DemoScope(
      places: placesForThisBuild,
      ledger: Ledger(),
      child: const DemoApp(),
    ),
  );
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF3F6B5C);
    return MaterialApp(
      title: 'p0g demo',
      theme: ThemeData(colorSchemeSeed: seed),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: const DemoHome(),
    );
  }
}
