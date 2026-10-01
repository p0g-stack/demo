import 'dart:async';

import 'package:logging/logging.dart';
import 'package:squadron/squadron.dart';

import '../facts/facts.dart';
import '../log.dart';
import '../native/native.dart';
import '../rust/api/demo.dart' as rust;
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

  /// Runs where the service runs: its logs reach the caller's sink.
  DemoService() {
    forwardLogs();
  }

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

  /// The same work as [crunch] in the demo crate (`rust/`), loaded in this
  /// place by the brick's [loadNative]: native code on the VM, wasm in a
  /// browser or Web Worker. Returns what the crate was built for and its
  /// times, or `error` when it cannot load here (the `native` fact is false).
  @squadronMethod
  Future<Map<String, dynamic>> rustCrunch(int n) async {
    final load = Stopwatch()..start();
    if (!await loadNative()) {
      _log.warning('demo crate did not load here');
      return {
        'error':
            'the demo crate did not load in this place (native fact false; '
            'build it with tool/rust.sh)',
      };
    }
    final loadMs = load.elapsedMilliseconds;
    final sw = Stopwatch()..start();
    final count = rust.countPrimes(n: n);
    final target = rust.buildTarget();
    _log.fine('rustCrunch($n) = $count on $target');
    return {
      'target': target,
      'loadMs': loadMs,
      'count': count,
      'ms': sw.elapsedMilliseconds,
    };
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
  /// [off]; the objective picks the strategy inside the place and logs the
  /// run there. Returns what it picked and why, so the caller can log it too
  /// (records logged inside a worker stay in that worker).
  @squadronMethod
  Future<Map<String, dynamic>> partitions(List<String> off) async {
    final current = await PlaceInfo.current();
    final here = PlaceInfo(current.kind, withoutFacts(current.facts, off));
    final selection = partitionsObjective.selectRead(here);
    final sw = Stopwatch()..start();
    final rows = await partitionsObjective.run(null, here);
    return {
      'strategy': selection.chosen?.name,
      'why': selection.why,
      'facts': here.facts.present,
      'ms': sw.elapsedMilliseconds,
      'rows': [for (final p in rows) p.toJson()],
    };
  }
}
