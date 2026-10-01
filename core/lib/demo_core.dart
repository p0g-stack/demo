/// The demo's pure Dart core: the demo service, its places, strategies and
/// the run ledger. No `package:flutter`, so the CLI and the workers can run it.
library;

export 'package:squadron_process/squadron_process.dart'
    show
        Fact,
        PlaceFacts,
        Place,
        LocalPlace,
        ProcessPlace,
        ProcessEndpoint,
        PlaceKind;

export 'src/ledger.dart';
export 'src/places/places.dart';
export 'src/service/demo_service.dart';
export 'src/strategy/strategy.dart';
export 'src/tasks/partitions.dart';
