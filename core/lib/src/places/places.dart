import 'package:squadron_process/squadron_process.dart' as sp;

import '../facts/facts.dart';

import '../service/demo_service.dart';

/// A place as the pages list it: squadron_process places plus the caller
/// itself, and places this build cannot open (shown, with the reason).
abstract class DemoPlace {
  String get id;
  String get label;

  /// `inline`, or a squadron_process place kind.
  String get kind;

  /// Why this place does not exist here, or null when it does.
  String? get unavailable => null;

  /// The service as seen through this place.
  DemoService get service;

  /// What the place can do, as checked by the place itself.
  Future<sp.PlaceFacts> facts();

  Future<void> start() async {}
  void stop() {}
}

/// Runs the service in the caller: on the web that is the page's main thread,
/// so CPU work freezes the UI. That is the point of showing it.
final class InlinePlace extends DemoPlace {
  @override
  String get id => 'inline';
  @override
  String get label => 'inline (the caller)';
  @override
  String get kind => 'inline';
  @override
  final DemoService service = DemoService();

  /// The caller's own context, checked the way LocalPlace checks it.
  @override
  Future<sp.PlaceFacts> facts() async => Facts(await checkFacts());
}

/// [DemoServiceWorker] bound to a squadron_process place: an isolate or Web
/// Worker (`LocalPlace`), or another process (`ProcessPlace`).
final class SquadronPlace extends DemoPlace {
  SquadronPlace(this.id, this.label, this.place);

  @override
  final String id;
  @override
  final String label;
  final sp.Place place;
  DemoServiceWorker? _worker;

  @override
  String get kind => place.kind;

  @override
  DemoServiceWorker get service => _worker ??= place.bind(DemoServiceWorker());

  @override
  Future<void> start() => service.start();

  @override
  Future<sp.PlaceFacts> facts() => place.facts();

  @override
  void stop() {
    _worker?.stop();
    _worker = null;
  }
}

/// A place this build cannot open, kept in the list so pages show the
/// fallback instead of hiding the place.
final class MissingPlace extends DemoPlace {
  MissingPlace(this.id, this.label, this.unavailable);

  @override
  final String id;
  @override
  final String label;
  @override
  final String unavailable;
  @override
  String get kind => sp.PlaceKind.process;

  @override
  DemoService get service => throw StateError('$label: $unavailable');

  @override
  Future<sp.PlaceFacts> facts() async => const sp.PlaceFacts.none();
}

const _rootLabel = 'root process (the app CLI, serve mode)';

/// The places this app knows about, in the order pages show them.
///
/// [process] is the root process place when this build has a way to reach
/// one; otherwise it is listed as missing with [missingReason].
List<DemoPlace> demoPlaces({
  sp.ProcessPlace? process,
  String missingReason = 'no launcher for the root process in this build',
}) => [
  InlinePlace(),
  SquadronPlace('worker', 'worker (isolate or Web Worker)', localPlace),
  if (process != null)
    SquadronPlace('process', _rootLabel, process)
  else
    MissingPlace('process', _rootLabel, missingReason),
];

/// What opening a place cost and what it said about itself.
final class PlaceReport {
  const PlaceReport({
    required this.place,
    required this.facts,
    this.startMs,
    this.factsMs,
    this.error,
  });

  final DemoPlace place;

  /// What the place checked.
  final Facts facts;

  /// Time to start the place (spawn the isolate or Web Worker, or connect to
  /// the process and handshake).
  final int? startMs;

  /// Time to get the place's facts after start.
  final int? factsMs;
  final String? error;

  bool get ok => error == null;
}

/// Starts [place] and asks it for its facts, timing both.
Future<PlaceReport> openPlace(DemoPlace place) async {
  final missing = place.unavailable;
  if (missing != null) {
    return PlaceReport(place: place, facts: const Facts.none(), error: missing);
  }
  try {
    final sw = Stopwatch()..start();
    await place.start();
    final startMs = sw.elapsedMilliseconds;
    sw.reset();
    final facts = await place.facts();
    return PlaceReport(
      place: place,
      facts: facts,
      startMs: startMs,
      factsMs: sw.elapsedMilliseconds,
    );
  } catch (e) {
    return PlaceReport(place: place, facts: const Facts.none(), error: '$e');
  }
}
