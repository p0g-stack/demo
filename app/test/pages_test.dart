import 'dart:async';

import 'package:demo/pages/lifecycle/lifecycle_page.dart';
import 'package:demo/pages/lifecycle/run_store.dart';
import 'package:demo/pages/pages.dart';
import 'package:demo/pages/places/places_page.dart';
import 'package:demo/pages/strategy/strategy_page.dart';
import 'package:demo_core/demo_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A service that answers from fixed facts and never touches the machine.
base class FakeService extends DemoService {
  FakeService(this.have);

  final Set<String> have;

  @override
  Future<Map<String, dynamic>> facts() async => Facts(
    runtime: 'fake place',
    values: {for (final f in Fact.all) f: have.contains(f)},
    notes: {for (final f in Fact.all) f: 'fake'},
  ).toJson();

  @override
  Future<Map<String, dynamic>> crunch(int n) async => {'count': 1, 'ms': 2};

  @override
  Future<List<Map<String, dynamic>>> partitions(String id) async => [
    const Partition('boot_a', 1024).toJson(),
  ];

  @override
  Stream<Map<String, dynamic>> ticks(int count, int intervalMs) =>
      const Stream.empty();
}

final class FakePlace extends Place {
  FakePlace(this.id, Set<String> have) : service = FakeService(have);

  @override
  final String id;
  @override
  String get label => 'fake $id';
  @override
  final DemoService service;
}

Widget host(Widget page, List<Place> Function() places, [Ledger? ledger]) =>
    DemoScope(
      places: places,
      ledger: ledger ?? Ledger(),
      child: MaterialApp(home: Scaffold(body: page)),
    );

/// Tall enough that ListView builds every section.
void tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets(
    'Places shows facts per place and the fallback for a missing one',
    (tester) async {
      tall(tester);
      await tester.pumpWidget(
        host(
          const PlacesPage(),
          () => [
            FakePlace('worker', {Fact.net}),
            MissingPlace('root', 'root process', 'no root channel here'),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('reports itself as: fake place'),
        findsOneWidget,
      );
      expect(find.text('no root channel here'), findsOneWidget);
      expect(
        find.textContaining('Without it, work that needs root'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Strategy picks on-device with root and records the run', (
    tester,
  ) async {
    tall(tester);
    final ledger = Ledger();
    await tester.pumpWidget(
      host(
        const StrategyPage(),
        () => [
          FakePlace('root', {Fact.root, Fact.blockDevices, Fact.processSpawn}),
        ],
        ledger,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Chosen: on device'), findsOneWidget);
    await tester.tap(find.text('Run on_device in root'));
    await tester.pumpAndSettle();
    expect(find.textContaining('boot_a'), findsWidgets);
    expect(ledger.records.single.strategy, 'on_device');
    expect(ledger.records.single.place, 'root');
  });

  testWidgets('Strategy switches to the fallback when a fact is switched off', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(
      host(
        const StrategyPage(),
        () => [
          FakePlace('root', {Fact.root, Fact.blockDevices}),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, Fact.root));
    await tester.pumpAndSettle();
    expect(find.text('No strategy fits here'), findsOneWidget);
    expect(
      find.textContaining('Nothing runs, and the app says so'),
      findsOneWidget,
    );
  });

  testWidgets('Lifecycle reports a task the last close cut short', (
    tester,
  ) async {
    tall(tester);
    final store = MemoryRunStore(
      const RunState(
        place: 'worker',
        startedAt: 0,
        tick: 37,
        total: 600,
        lastAt: 0,
        status: 'running',
        lifecycle: 'hidden',
      ),
    );
    await tester.pumpWidget(
      host(LifecyclePage(store: store), () => [FakePlace('worker', const {})]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Last time: closed mid-task'), findsOneWidget);
    expect(find.textContaining('reached tick 37 of 600'), findsOneWidget);
  });
}
