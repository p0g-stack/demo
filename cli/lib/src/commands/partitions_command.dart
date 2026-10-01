import 'package:args/command_runner.dart';
import 'package:demo_core/demo_core.dart';

/// The Strategy page's task, run in the CLI's own process.
class PartitionsCommand extends Command<int> {
  PartitionsCommand() {
    argParser.addMultiOption(
      'off',
      help: 'Treat these facts as missing, to see the fallback.',
      allowed: checkedFacts,
    );
  }

  @override
  String get name => 'partitions';

  @override
  String get description =>
      'List partitions with the first strategy this process allows.';

  @override
  Future<int> run() async {
    final facts = withoutFacts(
      Facts(await checkFacts()),
      argResults!.multiOption('off'),
    );
    final place = Place('cli', facts);
    for (final s in partitionStrategies) {
      final missing = s.missing(facts);
      print(
        '${missing.isEmpty ? 'yes' : 'no '}  ${s.label}'
        '${missing.isEmpty ? '' : ' (missing ${missing.join(', ')})'}',
      );
    }
    try {
      for (final p in await partitionsObjective.run(null, place)) {
        print('  ${p.name.padRight(24)} ${p.bytes ?? '?'}');
      }
      return 0;
    } on NoStrategyAvailable catch (e) {
      print(e);
      return 2;
    }
  }
}
