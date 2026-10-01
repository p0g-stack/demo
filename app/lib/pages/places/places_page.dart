import 'package:demo_core/demo_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../common/facts_view.dart';
import '../pages.dart';

/// Page 1: the same service in each place, with what it cost and what the
/// place said about itself.
class PlacesPage extends StatefulWidget {
  const PlacesPage({super.key});

  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _Run {
  _Run({
    required this.wallMs,
    required this.inPlaceMs,
    required this.frames,
    this.error,
  });

  final int wallMs;
  final int? inPlaceMs;

  /// Frames the page drew while the work ran: 0 or 1 means the UI froze.
  final int frames;
  final String? error;
}

class _PlacesPageState extends State<PlacesPage>
    with SingleTickerProviderStateMixin {
  static const sizes = [200000, 1000000, 3000000];

  List<DemoPlace>? _places;
  final _reports = <String, PlaceReport>{};
  final _runs = <String, _Run>{};
  var _n = sizes[1];
  String? _running;
  late final Ticker _ticker;
  var _frames = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _frames++);
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
    _ticker.dispose();
    for (final p in _places ?? const <DemoPlace>[]) {
      p.stop();
    }
    super.dispose();
  }

  Future<void> _open() async {
    setState(() {
      _reports.clear();
      _runs.clear();
    });
    for (final p in _places!) {
      p.stop();
      final r = await openPlace(p);
      if (!mounted) return;
      setState(() => _reports[p.id] = r);
    }
  }

  Future<void> _runAll() async {
    final ledger = DemoScope.of(context).ledger;
    for (final p in _places!) {
      final report = _reports[p.id];
      if (report == null || !report.ok) continue;
      setState(() => _running = p.id);
      // Let the "running" state paint before inline work can block it.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      _frames = 0;
      _ticker.start();
      final sw = Stopwatch()..start();
      _Run run;
      try {
        final r = await ledger.track(
          task: 'crunch($_n)',
          place: p.id,
          facts: report.facts,
          body: () => p.service.crunch(_n),
        );
        run = _Run(
          wallMs: sw.elapsedMilliseconds,
          inPlaceMs: (r['ms'] as num).toInt(),
          frames: _frames,
        );
      } catch (e) {
        run = _Run(
          wallMs: sw.elapsedMilliseconds,
          inPlaceMs: null,
          frames: _frames,
          error: '$e',
        );
      }
      _ticker.stop();
      if (!mounted) return;
      setState(() => _runs[p.id] = run);
    }
    setState(() => _running = null);
  }

  @override
  Widget build(BuildContext context) {
    final places = _places ?? const <DemoPlace>[];
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'One service, DemoService, opened in every place this build knows. '
            'Each place probes its own facts from inside; the page never guesses '
            'from the platform it was built for.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<int>(
                segments: [
                  for (final s in sizes)
                    ButtonSegment(
                      value: s,
                      label: Text(
                        s >= 1000000 ? '${s ~/ 1000000}M' : '${s ~/ 1000}k',
                      ),
                    ),
                ],
                selected: {_n},
                onSelectionChanged: _running == null
                    ? (v) => setState(() => _n = v.single)
                    : null,
              ),
              FilledButton.icon(
                onPressed: _running == null ? _runAll : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Count primes in every place'),
              ),
              OutlinedButton.icon(
                onPressed: _running == null ? _open : null,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Restart places'),
              ),
              if (_running != null) ...[
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                Text('running in $_running'),
              ],
            ],
          ),
        ),
        for (final p in places) _placeCard(p),
      ],
    );
  }

  Widget _placeCard(DemoPlace p) {
    final report = _reports[p.id];
    final run = _runs[p.id];
    if (report == null) {
      return Section(title: p.label, child: const LinearProgressIndicator());
    }
    if (!report.ok) {
      return Section(
        title: p.label,
        subtitle: 'not available here',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report.error!),
            const SizedBox(height: 8),
            const Fallback(
              'Without it, work that needs root has no place to run: the Strategy '
              'page shows "no strategy fits", and everything else runs inline or in '
              'the worker.',
            ),
          ],
        ),
      );
    }
    return Section(
      title: p.label,
      subtitle: 'kind: ${p.kind}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'start ${report.startMs} ms, first facts() round trip ${report.factsMs} ms',
          ),
          if (run != null)
            Text(
              run.error != null
                  ? 'run failed: ${run.error}'
                  : 'crunch: ${run.inPlaceMs} ms inside, ${run.wallMs} ms seen by the page, '
                        '${run.frames} frames drawn meanwhile'
                        '${run.frames <= 1 ? ' (UI froze)' : ''}',
            ),
          const SizedBox(height: 8),
          FactsView(facts: report.facts),
        ],
      ),
    );
  }
}
