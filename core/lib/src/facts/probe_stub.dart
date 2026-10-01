import 'facts.dart';

Future<Facts> probe(String? as) async => Facts.none(as ?? 'unknown');
