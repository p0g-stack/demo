import 'package:demo_core/demo_core.dart';
import 'package:flutter/material.dart';

import 'home.dart';
import 'pages/pages.dart';

// Diverges from the p0g_app brick: main() opens the demo's pages instead of
// the single hello page. [App] stays as generated (tool/regen.sh lists this
// file).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final lines = LogLines();
  logTo((line) {
    debugPrint(line);
    lines.add(line);
  }, level: Level.ALL);
  runApp(
    DemoScope(places: placesForThisBuild, lines: lines, child: const DemoApp()),
  );
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: const DemoHome(),
    );
  }
}

class App extends StatelessWidget {
  const App({
    super.key,
    required this.place,
    required this.hello,
    required this.lines,
  });

  final Place place;
  final HelloService hello;
  final LogLines lines;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: HomePage(place: place, hello: hello, lines: lines),
    );
  }
}
