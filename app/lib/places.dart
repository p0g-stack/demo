import 'package:squadron/squadron.dart';
import 'package:demo_core/demo_core.dart';

/// A generated worker constructor, such as `HelloServiceWorker.new`.
typedef WorkerConstructor<W extends Worker> =
    W Function({
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager,
    });

/// The place the app's services run in, and how to start a worker there.
abstract interface class PlaceLink {
  Place get place;

  /// Start the worker for [service] in this place.
  Future<W> start<W extends Worker>(
    String service,
    WorkerConstructor<W> create,
  );

  Future<void> close();
}

/// Open the place for this run of the app.
Future<PlaceLink> openPlace() async {
  return LocalLink();
}

/// Squadron's own place: an isolate on native, a Web Worker on the web.
///
/// It reports no facts, because it has checked none; strategies that need
/// root or devices are unavailable here, which is the honest answer.
final class LocalLink implements PlaceLink {
  final _workers = <Worker>[];

  @override
  final Place place = Place(
    Squadron.platformType.isVm ? 'isolate' : 'web_worker',
  );

  @override
  Future<W> start<W extends Worker>(
    String service,
    WorkerConstructor<W> create,
  ) async {
    final worker = create();
    await worker.start();
    _workers.add(worker);
    return worker;
  }

  @override
  Future<void> close() async {
    for (final w in _workers) {
      w.terminate();
    }
  }
}
