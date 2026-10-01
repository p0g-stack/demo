import 'package:args/command_runner.dart';
import 'package:demo_core/demo_core.dart';

/// Runs the Places page workload in the CLI's own process.
class CrunchCommand extends Command<int> {
  CrunchCommand() {
    argParser.addOption(
      'n',
      defaultsTo: '2000000',
      help: 'Count primes below n.',
    );
  }

  @override
  String get name => 'crunch';

  @override
  String get description => 'Count primes in this process (Places workload).';

  @override
  Future<int> run() async {
    final r = await DemoService().crunch(int.parse(argResults!.option('n')!));
    print('${r['count']} primes in ${r['ms']} ms');
    return 0;
  }
}
