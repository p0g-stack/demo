import 'dart:io';

import 'partitions.dart';

Future<List<Partition>> readProcPartitions() async =>
    parseProcPartitions(await File('/proc/partitions').readAsString());

Future<List<Partition>> fastbootGetvarAll() async {
  final r = await Process.run('fastboot', const [
    'getvar',
    'all',
  ]).timeout(const Duration(seconds: 10));
  // fastboot prints getvar output on stderr.
  final out = '${r.stdout}\n${r.stderr}';
  if (r.exitCode != 0) {
    throw StateError('fastboot exited ${r.exitCode}: ${out.trim()}');
  }
  return parseFastbootGetvar(out);
}
