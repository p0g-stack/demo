import '../facts/facts.dart';
import '../service/demo_service.dart';

/// Somewhere [DemoService] can run: the caller itself, a Squadron worker
/// (an isolate on the Dart VM, a Web Worker on the web), or the root process.
///
/// Interim: `squadron_process` will provide the places and their facts; this
/// is the smallest stand-in so the pages can take shape now.
abstract class Place {
  String get id;
  String get label;

  /// Why this place does not exist here, or null when it does.
  String? get unavailable => null;

  /// The service as seen through this place.
  DemoService get service;

  Future<void> start() async {}
  void stop() {}
}

/// Runs the service in the caller: on the web that is the page's main thread,
/// so CPU work freezes the UI. That is the point of showing it.
final class InlinePlace extends Place {
  @override
  String get id => 'inline';
  @override
  String get label => 'inline (the caller)';
  @override
  final DemoService service = DemoService();
}

/// A Squadron worker: an isolate on the Dart VM, a Web Worker on the web.
final class WorkerPlace extends Place {
  DemoServiceWorker? _worker;

  @override
  String get id => 'worker';
  @override
  String get label => 'worker (isolate or Web Worker)';

  @override
  DemoService get service => _worker ??= DemoServiceWorker();

  @override
  Future<void> start() => (_worker ??= DemoServiceWorker()).start();

  @override
  void stop() {
    _worker?.stop();
    _worker = null;
  }
}

/// A place this build cannot open, kept in the list so pages show the
/// fallback instead of hiding the place.
final class MissingPlace extends Place {
  MissingPlace(this.id, this.label, this.unavailable);

  @override
  final String id;
  @override
  final String label;
  @override
  final String unavailable;

  @override
  DemoService get service => throw StateError('$label: $unavailable');
}

/// The places this app knows about, in the order pages show them.
List<Place> defaultPlaces() => [
  InlinePlace(),
  WorkerPlace(),
  MissingPlace(
    'root',
    'root process (the app CLI, serve mode)',
    'needs squadron_process and the flutter-webui root channel; '
        'neither is wired into the demo yet',
  ),
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

  final Place place;
  final Facts facts;

  /// Time to start the place (spawn the isolate or Web Worker).
  final int? startMs;

  /// Round trip of the first facts() call after start.
  final int? factsMs;
  final String? error;

  bool get ok => error == null;
}

/// Starts [place] and asks it for its facts, timing both.
Future<PlaceReport> openPlace(Place place) async {
  final missing = place.unavailable;
  if (missing != null) {
    return PlaceReport(
      place: place,
      facts: Facts.none(place.label),
      error: missing,
    );
  }
  try {
    final sw = Stopwatch()..start();
    await place.start();
    final startMs = sw.elapsedMilliseconds;
    sw.reset();
    final facts = Facts.fromJson(await place.service.facts());
    return PlaceReport(
      place: place,
      facts: facts,
      startMs: startMs,
      factsMs: sw.elapsedMilliseconds,
    );
  } catch (e) {
    return PlaceReport(
      place: place,
      facts: Facts.none(place.label),
      error: '$e',
    );
  }
}
