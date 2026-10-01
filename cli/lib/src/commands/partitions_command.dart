import 'package:args/command_runner.dart';
import 'package:demo_core/demo_core.dart';

import '../runner.dart';

/// The Strategy page's objective, run in the CLI's own process.
class PartitionsCommand extends Command<int> {
  PartitionsCommand() {
    argParser.addMultiOption(
      'off',
      help: 'Treat these facts as missing, to see the fallback.',
      allowed: Fact.all,
    );
  }

  @override
  String get name => 'partitions';

  @override
  String get description =>
      'List partitions with the first strategy this process allows.';

  @override
  Future<int> run() async {
    final cli = await cliPlace();
    final place = PlaceInfo(
      cli.kind,
      withoutFacts(cli.facts, argResults!.multiOption('off')),
    );
    print(partitionsObjective.selectRead(place).why);
    try {
      for (final p in await partitionsObjective.run(null, place)) {
        print('  ${p.name.padRight(24)} ${p.bytes ?? '?'}');
      }
      return 0;
    } on NoStrategyAvailable {
      return 2;
    }
  }
}
