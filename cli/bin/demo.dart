import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:demo_core/demo_core.dart';
import 'package:squadron_process/io.dart';

/// The demo's CLI. On WebUI it is also the root process: `serve` hosts
/// DemoService as a squadron_process place.
Future<void> main(List<String> args) async {
  if (args.firstOrNull == 'serve') {
    // serve owns stdout (its first line is the ready line) and exits by the
    // lifetime rule: closed stops.
    exit(await serve(DemoServiceWorker(), args.skip(1).toList()));
  }
  final runner = CommandRunner<void>('demo', 'p0g-stack demo CLI.')
    ..addCommand(FactsCommand())
    ..addCommand(CrunchCommand())
    ..addCommand(PartitionsCommand());
  try {
    await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exitCode = 64;
  }
}

class FactsCommand extends Command<void> {
  @override
  final name = 'facts';
  @override
  final description = 'Print what this process can do.';

  @override
  Future<void> run() async {
    final f = await checkFacts();
    for (final fact in Fact.all) {
      stdout.writeln('${f.has(fact) ? 'yes' : 'no '}  $fact');
    }
  }
}

class CrunchCommand extends Command<void> {
  CrunchCommand() {
    argParser.addOption(
      'n',
      defaultsTo: '2000000',
      help: 'Count primes below n.',
    );
  }

  @override
  final name = 'crunch';
  @override
  final description = 'Run the Places page workload in this process.';

  @override
  Future<void> run() async {
    final r = await DemoService().crunch(int.parse(argResults!['n'] as String));
    stdout.writeln('${r['count']} primes in ${r['ms']} ms');
  }
}

class PartitionsCommand extends Command<void> {
  PartitionsCommand() {
    argParser.addMultiOption(
      'mask',
      help: 'Treat these facts as missing, to see the fallback.',
      allowed: Fact.all,
    );
  }

  @override
  final name = 'partitions';
  @override
  final description =
      'List partitions with the first strategy this process allows.';

  @override
  Future<void> run() async {
    final facts = withoutFacts(
      await checkFacts(),
      (argResults!['mask'] as List<String>).toSet(),
    );
    final selection = pick(partitionStrategies, facts);
    stdout.writeln(selection.why);
    final chosen = selection.chosen as PartitionStrategy?;
    if (chosen == null) {
      exitCode = 2;
      return;
    }
    final ledger = Ledger();
    try {
      final parts = await ledger.track(
        task: 'partitions',
        strategy: chosen.id,
        place: 'cli',
        facts: facts,
        body: chosen.run,
      );
      for (final p in parts) {
        stdout.writeln('  ${p.name.padRight(24)} ${p.bytes ?? '?'}');
      }
    } catch (_) {
      stderr.writeln(ledger.records.last);
      exitCode = 1;
    }
  }
}
