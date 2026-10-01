import 'dart:io';

import 'partitions.dart';

/// Runs [s] in this process. [Objective] already checked this place's facts.
Future<List<Partition>> runHere(PartitionStrategy s) async => switch (s) {
  OnDevicePartitions() => parseProcPartitions(
    await File('/proc/partitions').readAsString(),
  ),
  FromHostPartitions() => _fastbootGetvarAll(),
  _ => throw ArgumentError.value(s.name, 'strategy'),
};

Future<List<Partition>> _fastbootGetvarAll() async {
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
