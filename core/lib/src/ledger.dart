import 'dart:async';
import 'dart:developer' as developer;

import 'facts/facts.dart';

/// One call, as the app accounts for it: what ran, where, with what facts.
final class RunRecord {
  const RunRecord({
    required this.task,
    required this.place,
    required this.facts,
    required this.at,
    required this.elapsed,
    required this.outcome,
    this.strategy,
  });

  final String task;
  final String? strategy;
  final String place;
  final Facts facts;
  final DateTime at;
  final Duration elapsed;

  /// `ok`, or the error text.
  final String outcome;

  bool get ok => outcome == 'ok';

  @override
  String toString() =>
      '$task'
      '${strategy == null ? '' : ' via $strategy'}'
      ' in $place: $outcome (${elapsed.inMilliseconds} ms) facts $facts';
}

/// Every call the app made, newest last. Records also go to the log.
final class Ledger {
  final _records = <RunRecord>[];
  final _changes = StreamController<RunRecord>.broadcast();

  List<RunRecord> get records => List.unmodifiable(_records);
  Stream<RunRecord> get changes => _changes.stream;

  void add(RunRecord r) {
    _records.add(r);
    developer.log(r.toString(), name: 'demo.ledger');
    _changes.add(r);
  }

  /// Runs [body] and records it, whether it succeeds or throws.
  Future<T> track<T>({
    required String task,
    required String place,
    required Facts facts,
    String? strategy,
    required Future<T> Function() body,
  }) async {
    final at = DateTime.now();
    final sw = Stopwatch()..start();
    try {
      final result = await body();
      add(
        RunRecord(
          task: task,
          strategy: strategy,
          place: place,
          facts: facts,
          at: at,
          elapsed: sw.elapsed,
          outcome: 'ok',
        ),
      );
      return result;
    } catch (e) {
      add(
        RunRecord(
          task: task,
          strategy: strategy,
          place: place,
          facts: facts,
          at: at,
          elapsed: sw.elapsed,
          outcome: '$e',
        ),
      );
      rethrow;
    }
  }
}
