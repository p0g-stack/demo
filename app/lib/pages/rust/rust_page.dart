import 'package:demo_core/demo_core.dart';
import 'package:flutter/material.dart';

import '../common/facts_view.dart';
import '../pages.dart';

/// Page 3: one Rust crate, compiled per place and called through frb from
/// whichever place runs the service: native code in an isolate or the CLI,
/// single-threaded wasm in the page or a Web Worker. Each place reports what
/// the crate was built for; where it cannot load, the Dart version runs.
class RustPage extends StatefulWidget {
  const RustPage({super.key});

  @override
  State<RustPage> createState() => _RustPageState();
}

class _Result {
  const _Result({this.rust, this.dart, this.error});

  final Map<String, dynamic>? rust;
  final Map<String, dynamic>? dart;
  final String? error;
}

class _RustPageState extends State<RustPage> {
  static const n = 1000000;
  static final _log = Logger('ui.rust');

  List<DemoPlace>? _places;
  final _reports = <String, PlaceReport>{};
  final _results = <String, _Result>{};
  String? _running;

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
      setState(() => _reports[p.id] = r);
    }
  }

  Future<void> _run(DemoPlace place) async {
    setState(() => _running = place.id);
    _Result result;
    try {
      final rust = await place.service.rustCrunch(n);
      final dart = await place.service.crunch(n);
      result = _Result(rust: rust, dart: dart);
      _log.info(
        rust.containsKey('error')
            ? 'rust in ${place.id}: not loaded (${rust['error']}); dart ${dart['ms']} ms'
            : 'rust in ${place.id} on ${rust['target']}: ${rust['ms']} ms, '
                  'dart ${dart['ms']} ms, init ${rust['initMs']} ms',
      );
    } catch (e) {
      result = _Result(error: '$e');
      _log.warning('rust page run in ${place.id} failed', e);
    }
    if (!mounted) return;
    setState(() {
      _results[place.id] = result;
      _running = null;
    });
  }

  Future<void> _runAll() async {
    for (final p in _places ?? const <DemoPlace>[]) {
      if (_reports[p.id]?.ok ?? false) await _run(p);
    }
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
            'The demo crate (rust/) counts the primes below $n with the same '
            'loop as page 1\'s Dart. The service loads it in its own place '
            'through flutter_rust_bridge, so each place runs its own build.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            onPressed: _running == null ? _runAll : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run in every place'),
          ),
        ),
        for (final p in places) _placeSection(p),
      ],
    );
  }

  Widget _placeSection(DemoPlace p) {
    final report = _reports[p.id];
    final result = _results[p.id];
    final rust = result?.rust;
    final dart = result?.dart;
    return Section(
      title: p.label,
      subtitle: report == null
          ? 'opening...'
          : report.ok
          ? null
          : 'not available: ${report.error}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report != null && !report.ok)
            Fallback(
              'Nothing runs in this place here, Rust or Dart. ${p.unavailable ?? ''}',
            )
          else ...[
            OutlinedButton(
              onPressed: report == null || _running != null
                  ? null
                  : () => _run(p),
              child: Text(_running == p.id ? 'Running...' : 'Run here'),
            ),
            if (result?.error != null) Text('Failed: ${result!.error}'),
            if (rust != null && rust.containsKey('error'))
              Fallback(
                'The crate did not load here: ${rust['error']}. '
                'The Dart version ran instead: ${dart?['ms']} ms.',
              )
            else if (rust != null) ...[
              Text('Built for: ${rust['target']}'),
              Text('Loaded from: ${rust['from']} in ${rust['initMs']} ms'),
              Text(
                'Rust ${rust['ms']} ms, Dart ${dart?['ms']} ms '
                '(${rust['count'] == dart?['count'] ? 'same count' : 'counts differ'}: ${rust['count']})',
              ),
            ],
          ],
        ],
      ),
    );
  }
}
