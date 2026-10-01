import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:demo_core/demo_core.dart';
import 'package:squadron_process/io.dart';

/// Hosts DemoService as a squadron_process place: the root process on WebUI.
///
/// Prints the ready line first on stdout and exits by the lifetime rule
/// (hidden keeps going, closed stops after the grace window).
class ServeCommand extends Command<int> {
  @override
  final argParser = ArgParser.allowAnything();

  @override
  String get name => 'serve';

  @override
  String get description =>
      'Host DemoService for the app over a loopback socket '
      '([--port N] [--session-file PATH] [--grace-ms N] [--first-link-grace-ms N]).';

  @override
  Future<int> run() async {
    final code = await serve(
      DemoServiceWorker(),
      argResults!.rest,
      facts: checkFacts,
    );
    // The service's isolate would otherwise keep the VM alive.
    exit(code);
  }
}
