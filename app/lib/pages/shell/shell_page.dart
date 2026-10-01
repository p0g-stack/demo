import 'package:demo_core/demo_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webui_client/flutter_webui_client.dart';

import '../common/facts_view.dart';
import 'shell_report.dart';

/// Page 5: the shell basics a stock app expects (insets, keyboard, back,
/// exit, light and dark) through Flutter's own APIs, what this host gives
/// for each, and what every known host would give, from flutter-webui's
/// fakes.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key, this.host});

  /// The host to report on; [WebUi.host] when null.
  final WebUiHost? host;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  static final _log = Logger('ui.shell');

  var _holdBack = false;
  var _backs = 0;
  String? _exit;
  Brightness? _preview;
  var _fake = 0;

  void _onPop(bool didPop, Object? _) {
    if (didPop) return;
    setState(() => _backs++);
    _log.info('back at the page root ($_backs), held by PopScope');
  }

  Future<void> _pop(WebUiHost host) async {
    await SystemNavigator.pop();
    _log.info('SystemNavigator.pop() on ${host.kind.name}');
    if (!mounted) return;
    setState(
      () => _exit = host.canExit
          ? 'Sent; the host closes the page.'
          : 'Still here: this host has no exit method, so the call does '
                'nothing (a browser tab cannot close itself).',
    );
  }

  @override
  Widget build(BuildContext context) {
    final host = widget.host ?? WebUi.host;
    final mq = MediaQuery.of(context);
    final fake = fakeHosts[_fake];
    final body = ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'The app reads these through Flutter\'s own APIs and never asks '
            'which host it is in; flutter_webui maps each host onto them.',
          ),
        ),
        Section(
          title: 'What the app sees',
          subtitle: 'Live values from MediaQuery.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('viewPadding: ${_edges(mq.viewPadding)}'),
              Text('viewInsets: ${_edges(mq.viewInsets)}'),
              Text('platformBrightness: ${mq.platformBrightness.name}'),
              Text(
                'size: ${mq.size.width.round()} x ${mq.size.height.round()}',
              ),
              const SizedBox(height: 8),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Focus to raise the keyboard (viewInsets.bottom)',
                ),
              ),
            ],
          ),
        ),
        Section(
          title: 'Light and dark',
          subtitle: 'The app follows platformBrightness; preview either here.',
          child: SegmentedButton<Brightness?>(
            segments: const [
              ButtonSegment(value: null, label: Text('Follow')),
              ButtonSegment(value: Brightness.light, label: Text('Light')),
              ButtonSegment(value: Brightness.dark, label: Text('Dark')),
            ],
            selected: {_preview},
            onSelectionChanged: (s) => setState(() => _preview = s.first),
          ),
        ),
        Section(
          title: 'Back and exit',
          subtitle: 'Back is held only while the switch is on.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hold back at this page (PopScope)'),
                subtitle: Text('Back presses held: $_backs'),
                value: _holdBack,
                onChanged: (v) => setState(() => _holdBack = v),
              ),
              OutlinedButton(
                onPressed: () => _pop(host),
                child: const Text('SystemNavigator.pop()'),
              ),
              if (_exit != null) Text(_exit!),
            ],
          ),
        ),
        Section(
          title: 'This host: ${_hostName(host)}',
          subtitle: host.isWebUi
              ? 'ksu: ${host.ksuMethods.join(', ')}'
                    '${host.webuiMethods.isEmpty ? '' : '; webui: ${host.webuiMethods.join(', ')}'}'
              : 'No ksu bridge on this page.',
          child: _ReportView(shellReport(host)),
        ),
        Section(
          title: 'Every known host',
          subtitle:
              'What each manager reports, from flutter_webui_client\'s fakes '
              '(its docs/hosts.md).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (i, h) in fakeHosts.indexed)
                    ChoiceChip(
                      label: Text(h.label),
                      selected: i == _fake,
                      onSelected: (_) => setState(() => _fake = i),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_hostName(fake.host)}, module ${fake.host.moduleId ?? 'unknown'}',
              ),
              _ReportView(fake.report),
            ],
          ),
        ),
      ],
    );
    final page = PopScope<Object?>(
      canPop: !_holdBack,
      onPopInvokedWithResult: _onPop,
      child: body,
    );
    final preview = _preview;
    if (preview == null) return page;
    return Theme(
      data: ThemeData(
        brightness: preview,
        colorSchemeSeed: Theme.of(context).colorScheme.primary,
      ),
      child: Material(child: page),
    );
  }
}

String _hostName(WebUiHost host) => switch (host.kind) {
  WebUiHostKind.browser => 'browser tab',
  WebUiHostKind.webui => 'WebUI',
  WebUiHostKind.webuix => 'WebUI X',
};

String _edges(EdgeInsets e) =>
    'top ${e.top.round()}, bottom ${e.bottom.round()}, '
    'left ${e.left.round()}, right ${e.right.round()}';

class _ReportView extends StatelessWidget {
  const _ReportView(this.rows);

  final List<ShellRow> rows;

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r.feature}: ${r.host}'),
                if (r.fallback != null)
                  Text('Fallback: ${r.fallback}', style: small),
              ],
            ),
          ),
      ],
    );
  }
}
