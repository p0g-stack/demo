import 'dart:async';

import 'package:squadron/squadron.dart';

import '../facts/probe.dart';
import '../tasks/partitions.dart';
import 'demo_service.activator.g.dart';

part 'demo_service.worker.g.dart';

/// The one service every page runs, in whichever place the page picks.
///
/// Squadron generates `DemoServiceWorker` (an isolate on the Dart VM, a Web
/// Worker on the web). The same class also runs directly in the page.
@SquadronService(baseUrl: '~/workers', targetPlatform: TargetPlatform.all)
base class DemoService {
  /// What the place this service runs in can do, probed from inside it.
  @SquadronMethod()
  Future<Map<String, dynamic>> facts() async => (await probeFacts()).toJson();

  /// CPU work: counts the primes below [n] by trial division.
  /// Returns the count and the milliseconds spent inside the place.
  @SquadronMethod()
  Future<Map<String, dynamic>> crunch(int n) async {
    final sw = Stopwatch()..start();
    var count = 0;
    for (var i = 2; i < n; i++) {
      var prime = true;
      for (var d = 2; d * d <= i; d++) {
        if (i % d == 0) {
          prime = false;
          break;
        }
      }
      if (prime) count++;
    }
    return {'count': count, 'ms': sw.elapsedMilliseconds};
  }

  /// A long task: [count] ticks, one every [intervalMs]. Each tick carries
  /// the place's own clock, so the page can tell when it was produced.
  @SquadronMethod()
  Stream<Map<String, dynamic>> ticks(int count, int intervalMs) async* {
    for (var i = 1; i <= count; i++) {
      await Future<void>.delayed(Duration(milliseconds: intervalMs));
      yield {'i': i, 'at': DateTime.now().millisecondsSinceEpoch};
    }
  }

  /// Lists partitions with the strategy [id], after checking this place's
  /// own facts allow it.
  @SquadronMethod()
  Future<List<Map<String, dynamic>>> partitions(String id) async {
    final s = partitionStrategy(id);
    checkAvailable(s, await probeFacts());
    return [for (final p in await s.run()) p.toJson()];
  }
}
