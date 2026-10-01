import 'check_stub.dart'
    if (dart.library.io) 'check_io.dart'
    if (dart.library.js_interop) 'check_web.dart'
    as impl;
import '../facts.dart';

/// Checks the facts of the place this code runs in: the page, a worker, the
/// CLI or the root process. Each value is a check made here, now; nothing is
/// inferred from the platform the app was built for. Pass it to every
/// squadron_process place (`LocalPlace(check:)`, `serve(facts:)`).
Future<Map<String, Object?>> checkFacts() => impl.checkFacts();

/// The facts [checkFacts] checks, in display order.
const checkedFacts = [
  Fact.root,
  Fact.blockDevices,
  Fact.usbNative,
  Fact.usbWeb,
  Fact.processSpawn,
  Fact.fsPersistent,
  Fact.net,
];
