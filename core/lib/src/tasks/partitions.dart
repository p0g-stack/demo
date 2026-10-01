import '../facts/facts.dart';
import '../strategy/strategy.dart';
import 'partitions_stub.dart' if (dart.library.io) 'partitions_io.dart' as impl;

/// A partition as a strategy found it.
final class Partition {
  const Partition(this.name, this.bytes);

  final String name;
  final int? bytes;

  Map<String, dynamic> toJson() => {'name': name, 'bytes': bytes};

  factory Partition.fromJson(Map json) =>
      Partition(json['name'] as String, (json['bytes'] as num?)?.toInt());
}

/// The task the Strategy page runs: list the device's partitions.
///
/// CBM's real case in miniature: on the device as root, or from a host
/// over USB with fastboot.
abstract class PartitionStrategy extends Strategy {
  const PartitionStrategy();

  /// Runs inside the place; only call where [available] said yes.
  Future<List<Partition>> run();
}

/// Reads `/proc/partitions` on the device itself; needs root to see block
/// devices (Android's SELinux hides them from apps).
final class OnDevicePartitions extends PartitionStrategy {
  const OnDevicePartitions();

  @override
  String get id => 'on_device';
  @override
  String get label => 'on device (/proc/partitions as root)';
  @override
  Set<String> get requires => const {Fact.root, Fact.blockDevices};

  @override
  Future<List<Partition>> run() => impl.readProcPartitions();
}

/// Asks a USB-attached device in fastboot mode, from a host.
final class FromHostPartitions extends PartitionStrategy {
  const FromHostPartitions();

  @override
  String get id => 'from_host';
  @override
  String get label => 'from host (fastboot getvar all)';
  @override
  Set<String> get requires => const {Fact.usbNative, Fact.processSpawn};

  @override
  Future<List<Partition>> run() => impl.fastbootGetvarAll();
}

/// Preference order: on the device first, then from a host.
const partitionStrategies = <PartitionStrategy>[
  OnDevicePartitions(),
  FromHostPartitions(),
];

PartitionStrategy partitionStrategy(String id) =>
    partitionStrategies.firstWhere(
      (s) => s.id == id,
      orElse: () => throw ArgumentError.value(id, 'id', 'no such strategy'),
    );

/// Parses `/proc/partitions` (major minor #blocks name; blocks of 1 KiB).
List<Partition> parseProcPartitions(String text) => [
  for (final line in text.split('\n').skip(2))
    if (line.trim().split(RegExp(r'\s+')) case [_, _, final kb, final name])
      Partition(name, int.tryParse(kb) == null ? null : int.parse(kb) * 1024),
];

/// Parses `fastboot getvar all` output (`(bootloader) partition-size:boot: 0x...`).
List<Partition> parseFastbootGetvar(String text) {
  final re = RegExp(r'partition-size:([^:\s]+):\s*(0x[0-9a-fA-F]+|\d+)');
  return [
    for (final m in re.allMatches(text))
      Partition(m.group(1)!, int.tryParse(m.group(2)!)),
  ];
}

/// Facts the place must have for [s], used by the service as a guard.
void checkAvailable(PartitionStrategy s, Facts facts) {
  final a = s.available(facts);
  if (!a.ok) throw StateError('${s.label}: ${a.reason}');
}
