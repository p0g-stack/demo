import 'dart:async';

import 'package:logging/logging.dart';
import 'package:squadron/squadron.dart';

import '../facts.dart';
import '../facts_check/check.dart';
import '../place.dart';
import '../tasks/partitions.dart';
import 'demo_service.activator.g.dart';

part 'demo_service.worker.g.dart';

/// The one service every demo page runs, in whichever place the page picks:
/// inline, a Squadron worker (isolate or Web Worker), or the app's CLI as the
/// root process.
@SquadronService(
  baseUrl: '~/workers',
  targetPlatform: TargetPlatform.vm | TargetPlatform.web,
)
base class DemoService {
  static final _log = Logger('service.demo');

  /// CPU work: counts the primes below [n] by trial division.
  /// Returns the count and the milliseconds spent inside the place.
  @squadronMethod
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
    _log.fine('crunch($n) = $count');
    return {'count': count, 'ms': sw.elapsedMilliseconds};
  }

  /// A long task: [count] ticks, one every [intervalMs]. Each tick carries
  /// the place's own clock, so the page can tell when it was produced.
  @squadronMethod
  Stream<Map<String, dynamic>> ticks(int count, int intervalMs) async* {
    for (var i = 1; i <= count; i++) {
      await Future<void>.delayed(Duration(milliseconds: intervalMs));
      yield {'i': i, 'at': DateTime.now().millisecondsSinceEpoch};
    }
  }

  /// Runs the `partitions` objective here, with this place's own facts minus
  /// [off]. [place] names the place for the run record. Returns the strategy
  /// that ran, the facts it saw, the time and the rows.
  @squadronMethod
  Future<Map<String, dynamic>> partitions(
    String place,
    List<String> off,
  ) async {
    final facts = withoutFacts(Facts(await checkFacts()), off);
    final here = Place(place, facts);
    final strategy = partitionsObjective.availableIn(here).firstOrNull;
    final sw = Stopwatch()..start();
    final rows = await partitionsObjective.run(null, here);
    return {
      'strategy': strategy?.name,
      'facts': facts.present,
      'ms': sw.elapsedMilliseconds,
      'rows': [for (final p in rows) p.toJson()],
    };
  }
}
