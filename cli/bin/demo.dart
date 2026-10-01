import 'dart:io';

import 'package:demo_cli/demo_cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await AppRunner().run(args);
}
