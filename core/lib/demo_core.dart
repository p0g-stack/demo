/// The logic of demo, shared by the Flutter app and the CLI.
///
/// Pure Dart: this library never imports `package:flutter`, because the CLI
/// runs it on the plain Dart VM.
library;

export 'package:logging/logging.dart' show Level, LogRecord, Logger;

export 'src/facts.dart';
export 'src/log.dart';
export 'src/objective.dart';
export 'src/place.dart';
export 'src/services/hello_service.dart';
export 'src/facts_check/check.dart';
export 'src/places/places.dart';
export 'src/services/demo_service.dart';
export 'src/tasks/partitions.dart';
export 'package:squadron_process/squadron_process.dart'
    show LocalPlace, PlaceFacts, PlaceKind, ProcessEndpoint, ProcessPlace;

// p0g:exports (bricks insert exports above this line)
