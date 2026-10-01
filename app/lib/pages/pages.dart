import 'package:demo_core/demo_core.dart';
import 'package:flutter/material.dart';

import '../home.dart' show LogLines;

import 'lifecycle/lifecycle_page.dart';
import 'places/places_page.dart';
import 'strategy/strategy_page.dart';

/// What every page shares: how to make its places, and the log lines.
class DemoScope extends InheritedWidget {
  const DemoScope({
    super.key,
    required this.places,
    required this.lines,
    required super.child,
  });

  /// Each page opens its own places, so one page restarting a worker never
  /// stops another page's task.
  final List<DemoPlace> Function() places;

  /// Every log record, formatted (the brick's `logTo` convention).
  final LogLines lines;

  static DemoScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DemoScope>()!;

  @override
  bool updateShouldNotify(DemoScope oldWidget) =>
      places != oldWidget.places || lines != oldWidget.lines;
}

/// The places this build offers.
///
/// The root process needs a launcher: on WebUI the p0g_app brick wires one
/// over flutter-webui's root channel. Until then, a page can be pointed at a
/// running `demo serve` for development: `?place=<port>&token=<token>`.
List<DemoPlace> placesForThisBuild() {
  final q = Uri.base.queryParameters;
  final port = int.tryParse(q['place'] ?? '');
  final token = q['token'];
  return demoPlaces(
    process: port != null && token != null
        ? ProcessPlace(
            endpoint: ProcessEndpoint(port: port, token: token),
          )
        : null,
    missingReason:
        'no launcher in this build yet (the WebUI one comes with the p0g_app '
        'brick over flutter-webui\'s root channel); for development, run '
        '`demo serve` and open ?place=<port>&token=<token>',
  );
}

class DemoPage {
  const DemoPage(this.title, this.icon, this.builder);

  final String title;
  final IconData icon;
  final WidgetBuilder builder;
}

/// One page per thing the stack promises. Pages 3, 5 and 6 (Rust, Shell
/// basics, Plugins) come next.
final demoPages = <DemoPage>[
  DemoPage('Places', Icons.hub_outlined, (_) => const PlacesPage()),
  DemoPage('Strategy', Icons.alt_route, (_) => const StrategyPage()),
  DemoPage('Lifecycle', Icons.timelapse, (_) => const LifecyclePage()),
];

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final page = demoPages[_index];
    return Scaffold(
      appBar: AppBar(title: Text(page.title)),
      // Keep every page alive so a running task survives switching pages.
      body: SelectionArea(
        child: IndexedStack(
          index: _index,
          children: [for (final p in demoPages) Builder(builder: p.builder)],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final p in demoPages)
            NavigationDestination(icon: Icon(p.icon), label: p.title),
        ],
      ),
    );
  }
}
