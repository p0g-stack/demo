import 'dart:async';

import 'package:demo_core/demo_core.dart';
import 'package:flutter/material.dart';

import '../common/facts_view.dart';
import '../pages.dart';
import 'run_store.dart';

/// Page 4: a long task you start, then leave or close the app.
///
/// Hidden keeps going: the place keeps producing ticks on its own clock while
/// the page is away. Closed stops: the next start finds the last saved tick
/// and says the task did not continue.
class LifecyclePage extends StatefulWidget {
  const LifecyclePage({super.key, this.store});

  final RunStore? store;

  @override
  State<LifecyclePage> createState() => _LifecyclePageState();
}

class _Away {
  _Away(this.from, this.state, this.tickAtLeave);

  final DateTime from;
  final AppLifecycleState state;
  final int tickAtLeave;
}

class _LifecyclePageState extends State<LifecyclePage> {
  static const intervalMs = 500;
  static const total = 600; // five minutes

  late final RunStore _store = widget.store ?? RunStore();
  late final AppLifecycleListener _listener;
  List<DemoPlace>? _places;
  final _reports = <String, PlaceReport>{};
  String? _placeId;

  RunState? _previous;
  RunState? _run;
  StreamSubscription<Map<String, dynamic>>? _sub;
  var _state = AppLifecycleState.resumed;
  _Away? _away;
  int _lastAt = 0;
  int _maxGapMs = 0;
  final _log = <String>[];

  @override
  void initState() {
    super.initState();
    _previous = _store.load();
    _state =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _listener = AppLifecycleListener(onStateChange: _onState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_places == null) {
      _places = DemoScope.of(context).places();
      _open();
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    _sub?.cancel();
    for (final p in _places ?? const <DemoPlace>[]) {
      p.stop();
    }
    super.dispose();
  }

  Future<void> _open() async {
    for (final p in _places!) {
      final r = await openPlace(p);
      if (!mounted) return;
      setState(() {
        _reports[p.id] = r;
        // Default to the place most likely to keep going while hidden: the
        // root process (its own OS process), then the worker, then inline.
        if (r.ok && _rank(p.id) > _rank(_placeId)) _placeId = p.id;
      });
    }
  }

  static int _rank(String? id) => switch (id) {
    'process' => 3,
    'worker' => 2,
    'inline' => 1,
    _ => 0,
  };

  String _clock(DateTime t) => t.toIso8601String().substring(11, 19);

  void _onState(AppLifecycleState s) {
    final now = DateTime.now();
    setState(() {
      _log.insert(0, '${_clock(now)}  ${_state.name} -> ${s.name}');
      if (s != AppLifecycleState.resumed &&
          _away == null &&
          _run?.status == 'running') {
        _away = _Away(now, s, _run!.tick);
      }
      if (s == AppLifecycleState.resumed && _away != null) {
        final a = _away!;
        final made = (_run?.tick ?? a.tickAtLeave) - a.tickAtLeave;
        final secs = now.difference(a.from).inMilliseconds / 1000;
        final expected = (secs * 1000 / intervalMs).floor();
        _log.insert(
          0,
          '${_clock(now)}  away ${secs.toStringAsFixed(1)} s: the place produced '
          '$made ticks (on schedule: $expected); longest gap $_maxGapMs ms',
        );
        _away = null;
      }
      _state = s;
    });
    final run = _run;
    if (run != null) _save(run.copyWith(lifecycle: s.name));
  }

  void _save(RunState s) {
    _run = s;
    _store.save(s);
  }

  void _start() {
    final place = _places!.firstWhere((p) => p.id == _placeId);
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastAt = now;
    _maxGapMs = 0;
    setState(() {
      _save(
        RunState(
          place: place.id,
          startedAt: now,
          tick: 0,
          total: total,
          lastAt: now,
          status: 'running',
          lifecycle: _state.name,
        ),
      );
      _log.insert(0, '${_clock(DateTime.now())}  started in ${place.id}');
    });
    _sub = place.service
        .ticks(total, intervalMs)
        .listen(
          (t) {
            final at = (t['at'] as num).toInt();
            final gap = at - _lastAt;
            _lastAt = at;
            if (gap > _maxGapMs) _maxGapMs = gap;
            // Save even when hidden: that is what the next start reads.
            _save(_run!.copyWith(tick: (t['i'] as num).toInt(), lastAt: at));
            if (mounted) setState(() {});
          },
          onDone: () {
            _save(_run!.copyWith(status: 'done'));
            if (mounted) setState(() {});
          },
          onError: (Object e) {
            _save(_run!.copyWith(status: 'stopped'));
            if (mounted) setState(() => _log.insert(0, 'error: $e'));
          },
        );
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
    setState(() {
      _save(_run!.copyWith(status: 'stopped'));
      _log.insert(0, '${_clock(DateTime.now())}  stopped by you');
    });
  }

  @override
  Widget build(BuildContext context) {
    final run = _run;
    final running = run?.status == 'running';
    final report = _reports[_placeId];
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Start a five-minute task, then switch away (Home, another app or tab) '
            'and come back: hidden keeps going. Close the app instead and reopen it: '
            'closed stops, and this page says where the task was when it ended.',
          ),
        ),
        if (_previous case final p? when p.status == 'running')
          Section(
            title: 'Last time: closed mid-task',
            child: Fallback(
              'A task in ${p.place} reached tick ${p.tick} of ${p.total} at '
              '${_clock(DateTime.fromMillisecondsSinceEpoch(p.lastAt))} (app was '
              '${p.lifecycle}) and did not continue after the app closed. '
              'In the root process the same task will be cancelled after a short '
              'grace window once that place exists.',
            ),
          )
        else if (_previous case final p?)
          Section(
            title: 'Last time',
            child: Text(
              'A task in ${p.place} ended ${p.status} at tick ${p.tick} of ${p.total}.',
            ),
          ),
        Section(
          title: 'Task',
          subtitle:
              'tick every $intervalMs ms, stamped with the place\'s own clock',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _places ?? const <DemoPlace>[])
                    ChoiceChip(
                      label: Text(p.label),
                      selected: p.id == _placeId,
                      onSelected: !running && _reports[p.id]?.ok == true
                          ? (_) => setState(() => _placeId = p.id)
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_placeId == 'worker' && _reports['process']?.ok != true)
                const Fallback(
                  'No root process here, so the worker runs it. A manager '
                  'WebView (WebUI X) can pause a Web Worker while the page is '
                  'hidden; long tasks belong in the root process on WebUI.',
                ),
              if (_placeId == 'inline')
                const Fallback(
                  'Inline runs on the page\'s own timers, which a hidden browser tab '
                  'throttles to about one per second: the gap shows it.',
                ),
              const SizedBox(height: 8),
              if (run != null) ...[
                LinearProgressIndicator(value: run.tick / run.total),
                const SizedBox(height: 4),
                Text(
                  '${run.status} in ${run.place}: tick ${run.tick}/${run.total}, '
                  'longest gap $_maxGapMs ms, app ${_state.name}',
                ),
              ],
              const SizedBox(height: 8),
              running
                  ? OutlinedButton.icon(
                      onPressed: _stop,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                    )
                  : FilledButton.icon(
                      onPressed: report?.ok == true ? _start : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                    ),
            ],
          ),
        ),
        Section(
          title: 'Lifecycle',
          child: Text(
            _log.isEmpty
                ? 'app ${_state.name}; no changes yet'
                : _log.join('\n'),
          ),
        ),
        if (report != null && report.ok)
          Section(
            title: 'Facts from ${report.place.label}',
            child: FactsView(facts: report.facts),
          ),
      ],
    );
  }
}
