import 'dart:convert';

import 'run_store_io.dart'
    if (dart.library.js_interop) 'run_store_web.dart'
    as impl;

/// The last long-task run, saved on every tick so the next start can tell
/// what happened after the app closed.
class RunState {
  const RunState({
    required this.place,
    required this.startedAt,
    required this.tick,
    required this.total,
    required this.lastAt,
    required this.status,
    required this.lifecycle,
  });

  final String place;
  final int startedAt;
  final int tick;
  final int total;
  final int lastAt;

  /// `running`, `done` or `stopped`. Read back as `running` means the app
  /// closed mid-task.
  final String status;

  /// The app lifecycle state when this was saved.
  final String lifecycle;

  RunState copyWith({
    int? tick,
    int? lastAt,
    String? status,
    String? lifecycle,
  }) => RunState(
    place: place,
    startedAt: startedAt,
    tick: tick ?? this.tick,
    total: total,
    lastAt: lastAt ?? this.lastAt,
    status: status ?? this.status,
    lifecycle: lifecycle ?? this.lifecycle,
  );

  Map<String, dynamic> toJson() => {
    'place': place,
    'startedAt': startedAt,
    'tick': tick,
    'total': total,
    'lastAt': lastAt,
    'status': status,
    'lifecycle': lifecycle,
  };

  static RunState? fromJson(String? s) {
    if (s == null) return null;
    try {
      final j = jsonDecode(s) as Map<String, dynamic>;
      return RunState(
        place: j['place'] as String,
        startedAt: j['startedAt'] as int,
        tick: j['tick'] as int,
        total: j['total'] as int,
        lastAt: j['lastAt'] as int,
        status: j['status'] as String,
        lifecycle: j['lifecycle'] as String,
      );
    } on Object {
      return null;
    }
  }
}

abstract class RunStore {
  RunState? load();
  void save(RunState s);

  factory RunStore() = _DefaultRunStore;
}

class _DefaultRunStore implements RunStore {
  @override
  RunState? load() => RunState.fromJson(impl.read());

  @override
  void save(RunState s) => impl.write(jsonEncode(s.toJson()));
}

/// For tests.
class MemoryRunStore implements RunStore {
  MemoryRunStore([this.state]);

  RunState? state;

  @override
  RunState? load() => state;

  @override
  void save(RunState s) => state = s;
}
