import 'facts.dart';
import 'probe_stub.dart'
    if (dart.library.io) 'probe_io.dart'
    if (dart.library.js_interop) 'probe_web.dart'
    as impl;

/// Asks the place this code is running in what it can do.
///
/// Call it inside the place (a worker, the CLI, the page), not on its behalf.
Future<Facts> probeFacts({String? as}) => impl.probe(as);
