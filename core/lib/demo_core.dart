/// The logic of demo, shared by the Flutter app, its workers
/// and the CLI.
///
/// Pure Dart: this library never imports `package:flutter`, because the CLI
/// runs it on the plain Dart VM.
library;

export 'package:logging/logging.dart' show Level, LogRecord, Logger;

export 'src/facts/facts.dart';
export 'src/log.dart';
export 'src/service/hello_service.dart';
export 'src/strategy/objective.dart';
export 'src/strategy/strategy.dart';
export 'src/places/places.dart';
export 'src/service/demo_service.dart';
export 'src/tasks/partitions.dart';

// p0g:exports (bricks insert exports above this line)
