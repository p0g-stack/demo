@TestOn('vm')
library;

import 'package:demo_core/demo_core.dart';
import 'package:test/test.dart';

void main() {
  test('inline and worker places run the same service', () async {
    for (final place in [InlinePlace(), WorkerPlace()]) {
      final report = await openPlace(place);
      expect(report.ok, isTrue, reason: report.error);
      expect(report.facts.values.keys, containsAll(Fact.all));
      final r = await place.service.crunch(1000);
      expect(r['count'], 168);
      final ticks = await place.service.ticks(3, 1).toList();
      expect(ticks.map((t) => t['i']), [1, 2, 3]);
      place.stop();
    }
  });

  test('a missing place reports why instead of throwing', () async {
    final root = defaultPlaces().last;
    final report = await openPlace(root);
    expect(report.ok, isFalse);
    expect(report.error, contains('squadron_process'));
  });

  test('ledger records failures too', () async {
    final ledger = Ledger();
    await expectLater(
      ledger.track(
        task: 't',
        place: 'p',
        facts: const Facts.none('p'),
        body: () async => throw StateError('nope'),
      ),
      throwsStateError,
    );
    expect(ledger.records.single.outcome, contains('nope'));
  });
}
