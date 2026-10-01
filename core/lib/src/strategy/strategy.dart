import 'package:squadron_process/squadron_process.dart';

/// One way to get a task done, with the facts it needs.
///
/// Strategies decide with [available], never with `kIsWeb` or `Platform`.
abstract class Strategy {
  const Strategy();

  String get id;
  String get label;

  /// Facts the strategy cannot run without.
  Set<String> get requires;

  /// Whether this strategy can run in a place with [facts], and if not, why.
  Availability available(PlaceFacts facts) => Availability(
    this,
    missing: {
      for (final f in requires)
        if (!facts.has(f)) f,
    },
  );
}

final class Availability {
  const Availability(this.strategy, {required this.missing});

  final Strategy strategy;
  final Set<String> missing;

  bool get ok => missing.isEmpty;

  String get reason => ok
      ? 'has ${strategy.requires.join(', ')}'
      : 'missing ${missing.join(', ')}';
}

/// Which strategy [pick] chose for a set of facts, and what it passed over.
final class Selection {
  const Selection(this.considered);

  /// Every strategy in preference order, with its availability.
  final List<Availability> considered;

  Strategy? get chosen {
    for (final a in considered) {
      if (a.ok) return a.strategy;
    }
    return null;
  }

  String get why {
    final c = chosen;
    if (c == null) {
      return 'no strategy fits: '
          '${considered.map((a) => '${a.strategy.label} ${a.reason}').join('; ')}';
    }
    final skipped = considered.takeWhile((a) => a.strategy != c);
    return [
      for (final s in skipped) '${s.strategy.label} skipped (${s.reason})',
      '${c.label} chosen (${considered.firstWhere((a) => a.ok).reason})',
    ].join('; ');
  }
}

/// Picks the first strategy, in preference order, that [facts] allow.
Selection pick(List<Strategy> strategies, PlaceFacts facts) =>
    Selection([for (final s in strategies) s.available(facts)]);

/// [facts] with [off] read as missing, to show a fallback. Facts can only be
/// taken away, never added.
PlaceFacts withoutFacts(PlaceFacts facts, Set<String> off) =>
    facts.merge({for (final f in off) f: false});
