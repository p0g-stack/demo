import 'partitions.dart';

Future<List<Partition>> runHere(PartitionStrategy s) => throw UnsupportedError(
  '${s.label}: no filesystem or processes in this place',
);
