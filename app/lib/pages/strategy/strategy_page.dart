import 'package:demo_core/demo_core.dart';
import 'package:flutter/material.dart';

import '../common/facts_view.dart';
import '../pages.dart';

/// Page 2: one task, two strategies, picked by `available(facts)`.
///
/// The task is CBM's in miniature: list the device's partitions on the device
/// as root, or from a host with fastboot.
class StrategyPage extends StatefulWidget {
  const StrategyPage({super.key});

  @override
  State<StrategyPage> createState() => _StrategyPageState();
}

class _StrategyPageState extends State<StrategyPage> {
  List<DemoPlace>? _places;
  final _reports = <String, PlaceReport>{};
  String? _placeId;
  final _masked = <String>{};
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

  PlaceFacts? get _facts {
    final f = _reports[_placeId]?.facts;
    return f == null ? null : withoutFacts(f, _masked);
  }

  Future<void> _run(PartitionStrategy s) async {
    final place = _place!;
    setState(() {
      _busy = true;
      _result = null;
      _error = null;
    });
    try {
      final rows = await DemoScope.of(context).ledger.track(
        task: 'partitions',
        strategy: s.id,
        place: place.id,
        facts: _facts!,
        body: () => place.service.partitions(s.id),
      );
      _result = [for (final r in rows) Partition.fromJson(r)];
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ledger = DemoScope.of(context).ledger;
    final facts = _facts;
    final selection = facts == null ? null : pick(partitionStrategies, facts);
    final chosen = selection?.chosen as PartitionStrategy?;
    final needed = {for (final s in partitionStrategies) ...s.requires};

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Task: list the device\'s partitions. Strategies in preference order: '
            'on the device as root, then from a host over USB. The first one the '
            'place\'s facts allow runs; nothing reads kIsWeb or Platform.',
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
                                () => on ? _masked.remove(f) : _masked.add(f),
                              )
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                FactsView(facts: facts, needed: needed, off: _masked),
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
                for (final a in selection.considered)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(a.ok ? Icons.check : Icons.close),
                    title: Text(a.strategy.label),
                    subtitle: Text(
                      'needs ${a.strategy.requires.join(' + ')}: ${a.reason}',
                    ),
                  ),
                if (chosen == null)
                  const Fallback(
                    'Nothing runs, and the app says so instead of failing. On WebUI this '
                    'task goes to the root process (uid 0, block devices); on a computer '
                    'it needs fastboot and a USB device.',
                  )
                else
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _run(chosen),
                    icon: const Icon(Icons.play_arrow),
                    label: Text('Run ${chosen.id} in ${_place!.id}'),
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
          title: 'Ledger',
          subtitle: 'Every call: strategy, place and the facts it saw.',
          child: StreamBuilder<RunRecord>(
            stream: ledger.changes,
            builder: (context, _) {
              final rows = ledger.records.reversed.take(8).toList();
              if (rows.isEmpty) return const Text('Nothing has run yet.');
              return Text(rows.map((r) => r.toString()).join('\n\n'));
            },
          ),
        ),
      ],
    );
  }
}
