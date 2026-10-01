import 'package:demo_core/demo_core.dart';
import 'package:flutter/material.dart';
import 'package:squadron_process/squadron_process.dart'
    show ProcessEndpoint, ProcessPlace;

import '../home.dart' show LogLines;
import '../places/places.dart';

import 'lifecycle/lifecycle_page.dart';
import 'places/places_page.dart';
import 'plugins/plugins_page.dart';
import 'rust/rust_page.dart';
import 'shell/shell_page.dart';
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

/// The places the pages offer: inline, the local Squadron place, and the
/// root process from the brick's [Places] (its launcher: `P0G_CLI` on a
/// desktop, flutter-webui's root channel on WebUI).
///
/// For development on plain web, where there is no launcher, a page can be
/// pointed at a running `demo serve`: `?place=<port>&token=<token>`.
List<DemoPlace> pagePlaces(Places places) {
  final q = Uri.base.queryParameters;
  final port = int.tryParse(q['place'] ?? '');
  final token = q['token'];
  return demoPlaces(
    process:
        places.process ??
        (port != null && token != null
            ? ProcessPlace(
                endpoint: ProcessEndpoint(port: port, token: token),
              )
            : null),
    missingReason:
        'no launcher here (P0G_CLI on a desktop, the root channel on WebUI); '
        'for development, run `demo serve` and open '
        '?place=<port>&token=<token>',
  );
}

/// Log lines from [Logger.root], kept for the app's life once the pages
/// first open (the brick's home keeps its own).
LogLines pageLog() {
  final lines = LogLines();
  Logger.root.onRecord.listen((r) => lines.add(formatRecord(r)));
  return lines;
}

/// The panel on the brick's home page that opens the demo's pages.
class PagesPanel extends StatelessWidget {
  const PagesPanel({super.key, required this.places});

  static Widget inPlace(Places places, String kind) =>
      PagesPanel(places: places);

  final Places places;

  static LogLines? _lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            title: Text('Demo pages'),
            subtitle: Text('One page per thing the stack promises.'),
          ),
          for (final (i, p) in demoPages.indexed)
            ListTile(
              leading: Icon(p.icon),
              title: Text(p.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DemoScope(
                    places: () => pagePlaces(places),
                    lines: _lines ??= pageLog(),
                    child: DemoHome(initial: i),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DemoPage {
  const DemoPage(this.title, this.icon, this.builder);

  final String title;
  final IconData icon;
  final WidgetBuilder builder;
}

/// One page per thing the stack promises.
final demoPages = <DemoPage>[
  DemoPage('Places', Icons.hub_outlined, (_) => const PlacesPage()),
  DemoPage('Strategy', Icons.alt_route, (_) => const StrategyPage()),
  DemoPage('Rust', Icons.memory, (_) => const RustPage()),
  DemoPage('Lifecycle', Icons.timelapse, (_) => const LifecyclePage()),
  DemoPage('Shell', Icons.phone_android, (_) => const ShellPage()),
  DemoPage('Plugins', Icons.extension_outlined, (_) => const PluginsPage()),
];

class DemoHome extends StatefulWidget {
  const DemoHome({super.key, this.initial = 0});

  final int initial;

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  late var _index = widget.initial;

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
