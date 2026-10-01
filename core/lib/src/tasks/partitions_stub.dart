import 'partitions.dart';

Future<List<Partition>> readProcPartitions() =>
    throw UnsupportedError('no filesystem in this place');

Future<List<Partition>> fastbootGetvarAll() =>
    throw UnsupportedError('cannot start processes in this place');
