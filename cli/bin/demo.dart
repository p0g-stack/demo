import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:demo_core/demo_core.dart';

/// The demo's CLI. On WebUI it is also the root process (`serve`, once
/// squadron_process provides the socket channel).
Future<void> main(List<String> args) async {
  final runner = CommandRunner<void>('demo', 'p0g-stack demo CLI.')
    ..addCommand(FactsCommand())
    ..addCommand(CrunchCommand())
    ..addCommand(PartitionsCommand())
    ..addCommand(ServeCommand());
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
    final f = await probeFacts(as: 'demo cli');
    stdout.writeln(f.runtime);
    for (final fact in Fact.all) {
      stdout.writeln(
        '  ${f.has(fact) ? 'yes' : 'no '}  $fact'
        '  (${f.notes[fact] ?? 'not reported'})',
      );
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
    final facts = (await probeFacts(as: 'demo cli'))
        .mask((argResults!['mask'] as List<String>).toSet());
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

class ServeCommand extends Command<void> {
  @override
  final name = 'serve';
  @override
  final description =
      'Host DemoService for the app over a socket (root process).';

  @override
  Future<void> run() async {
    stderr.writeln(
      'serve needs squadron_process (socket channel); not wired yet.',
    );
    exitCode = 69;
  }
}
