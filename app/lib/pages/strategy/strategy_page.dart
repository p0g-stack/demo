import 'package:demo_core/demo_core.dart';
import 'package:flutter/material.dart';

import '../common/facts_view.dart';
import '../pages.dart';

/// Page 2: one objective, two strategies, picked by `available(facts)`.
///
/// The objective is CBM's in miniature: list the device's partitions on the
/// device as root, or from a host with fastboot. The page shows the choice
/// for the picked place; the place itself makes it again when it runs.
class StrategyPage extends StatefulWidget {
  const StrategyPage({super.key});

  @override
  State<StrategyPage> createState() => _StrategyPageState();
}

class _StrategyPageState extends State<StrategyPage> {
  static final _log = Logger('objective.partitions');

  List<DemoPlace>? _places;
  final _reports = <String, PlaceReport>{};
  String? _placeId;
  final _off = <String>{};
  List<Partition>? _result;
  String? _error;
  var _busy = false;

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
        _placeId ??= r.ok ? p.id : null;
      });
    }
  }

  DemoPlace? get _place => _places?.where((p) => p.id == _placeId).firstOrNull;

  Facts? get _facts {
    final f = _reports[_placeId]?.facts;
    return f == null ? null : withoutFacts(f, _off);
  }

  Future<void> _run() async {
    final place = _place!;
    setState(() {
      _busy = true;
      _result = null;
      _error = null;
    });
    final sw = Stopwatch()..start();
    try {
      final r = await place.service.partitions(_off.toList());
      _result = [
        for (final row in r['rows'] as List) Partition.fromJson(row as Map),
      ];
      // Log at the call site: records logged inside a worker stay there.
      _log.info(
        StrategyRun(
          objective: 'partitions',
          strategy: '${r['strategy']}',
          place: place.id,
          facts: [for (final f in r['facts'] as List) '$f'],
          write: false,
          why: '${r['why']}',
          outcome: 'ok',
          elapsed: sw.elapsed,
        ),
      );
    } catch (e) {
      _error = '$e';
      _log.warning('partitions in ${place.id} failed', e);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final lines = DemoScope.of(context).lines;
    final facts = _facts;
    final selection = facts == null
        ? null
        : partitionsObjective.selectRead(PlaceInfo(_place!.kind, facts));
    final chosen = selection?.chosen as PartitionStrategy?;
    final needed = <String>{
      for (final s in partitionsObjective.strategies) ...s.requires,
    };

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Objective: list the device\'s partitions. Strategies in preference '
            'order: on the device as root, then from a host over USB. The first '
            'one the place\'s facts allow runs; nothing reads kIsWeb or Platform.',
          ),
        ),
        Section(
          title: 'Place',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _places ?? const <DemoPlace>[])
                ChoiceChip(
                  label: Text(p.label),
                  selected: p.id == _placeId,
                  onSelected: _reports[p.id]?.ok == true
                      ? (_) => setState(() {
                          _placeId = p.id;
                          _result = null;
                          _error = null;
                        })
                      : null,
                ),
            ],
          ),
        ),
        if (facts != null)
          Section(
            title: 'Facts from ${_place!.label}',
            subtitle: 'Switch a fact off to see the fallback. You can only take facts away.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final f in needed)
                      FilterChip(
                        label: Text(f),
                        selected: facts.has(f),
                        onSelected: (_reports[_placeId]?.facts.has(f) ?? false)
                            ? (on) => setState(
                                () => on ? _off.remove(f) : _off.add(f),
                              )
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                FactsView(facts: facts, needed: needed, off: _off),
              ],
            ),
          ),
        if (selection != null)
          Section(
            title: chosen == null
                ? 'No strategy fits here'
                : 'Chosen: ${chosen.label}',
            subtitle: selection.why,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (s, a) in selection.considered)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(a.ok ? Icons.check : Icons.close),
                    title: Text((s as PartitionStrategy).label),
                    subtitle: Text(
                      'needs ${s.requires.join(' + ')}: ${a.ok ? 'has them' : a.reason}',
                    ),
                  ),
                if (chosen == null)
                  const Fallback(
                    'Nothing runs, and the app says so instead of failing. On '
                    'WebUI this objective goes to the root process (uid 0, block '
                    'devices); on a computer it needs fastboot and a USB device.',
                  )
                else
                  FilledButton.icon(
                    onPressed: _busy ? null : _run,
                    icon: const Icon(Icons.play_arrow),
                    label: Text('Run ${chosen.name} in ${_place!.id}'),
                  ),
                if (_busy) const LinearProgressIndicator(),
                if (_error != null) Text('Failed: $_error'),
                if (_result != null)
                  Text(
                    _result!.isEmpty
                        ? 'No partitions reported.'
                        : _result!
                              .map((p) => '${p.name}  ${p.bytes ?? '?'} B')
                              .join('\n'),
                  ),
              ],
            ),
          ),
        Section(
          title: 'Log',
          subtitle:
              'Every run: objective, strategy, place and the facts it saw.',
          child: ValueListenableBuilder<List<String>>(
            valueListenable: lines,
            builder: (context, all, _) {
              final rows = all
                  .where((l) => l.contains('objective.'))
                  .toList()
                  .reversed
                  .take(8);
              return Text(
                rows.isEmpty ? 'Nothing has run yet.' : rows.join('\n\n'),
              );
            },
          ),
        ),
      ],
    );
  }
}
