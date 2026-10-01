@TestOn('vm')
library;

import 'package:demo_core/demo_core.dart';
import 'package:squadron_process/io.dart';
import 'package:test/test.dart';

void main() {
  Future<void> runsTheService(DemoPlace place) async {
    final report = await openPlace(place);
    expect(report.ok, isTrue, reason: report.error);
    expect(report.facts.keys, containsAll(Fact.all));
    final r = await place.service.crunch(1000);
    expect(r['count'], 168);
    final ticks = await place.service.ticks(3, 1).toList();
    expect(ticks.map((t) => t['i']), [1, 2, 3]);
    place.stop();
  }

  test('inline and worker places run the same service', () async {
    await runsTheService(InlinePlace());
    await runsTheService(SquadronPlace('worker', 'worker', const LocalPlace()));
  });

  test('a process place runs the same service over serve mode', () async {
    final served = await startServe(DemoServiceWorker());
    addTearDown(served.close);
    final place = SquadronPlace(
      'process',
      'process',
      ProcessPlace(endpoint: served.endpoint),
    );
    expect(place.kind, PlaceKind.process);
    await runsTheService(place);
  });

  test('a missing place reports why instead of throwing', () async {
    final report = await openPlace(demoPlaces().last);
    expect(report.ok, isFalse);
    expect(report.error, contains('no launcher'));
  });

  test('ledger records failures too', () async {
    final ledger = Ledger();
    await expectLater(
      ledger.track(
        task: 't',
        place: 'p',
        facts: const PlaceFacts.none(),
        body: () async => throw StateError('nope'),
      ),
      throwsStateError,
    );
    expect(ledger.records.single.outcome, contains('nope'));
  });
}
