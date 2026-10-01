import 'dart:io';

import 'package:squadron_process/io.dart' show checkFacts;

import 'partitions.dart';

/// Runs [s] in this process after checking this process's own facts.
Future<List<Partition>> runHere(PartitionStrategy s) async {
  final a = s.available(await checkFacts());
  if (!a.ok) throw StateError('${s.label}: ${a.reason}');
  return switch (s) {
    OnDevicePartitions() => parseProcPartitions(
      await File('/proc/partitions').readAsString(),
    ),
    FromHostPartitions() => _fastbootGetvarAll(),
    _ => throw ArgumentError.value(s.id, 'strategy'),
  };
}

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
