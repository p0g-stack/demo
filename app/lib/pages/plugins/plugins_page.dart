import 'package:flutter/material.dart';
import 'package:flutter_webui_client/flutter_webui_client.dart';

import '../common/facts_view.dart';

/// A stock plugin the demo will call unchanged, and how webui-packages
/// closes it on WebUI.
final class PluginRow {
  const PluginRow(this.plugin, this.webui, {this.inBrowser});

  /// The pub package an app depends on.
  final String plugin;

  /// The route on WebUI (webui-packages' table).
  final String webui;

  /// What the stock web implementation does in a browser tab, if it works.
  final String? inBrowser;
}

/// webui-packages' first packages (its README).
const plannedPlugins = [
  PluginRow(
    'file_selector',
    'file_selector_webui: WebView chooser; a root listing when a real path is needed',
    inBrowser: 'the browser file picker',
  ),
  PluginRow(
    'share_plus',
    'share_plus_webui: Android share sheet through the app plane',
  ),
  PluginRow(
    'url_launcher',
    'url_launcher_webui: start an activity through the app plane',
    inBrowser: 'a new tab',
  ),
  PluginRow(
    'path_provider',
    'path_provider_webui: module and state dirs over the root channel',
  ),
];

/// Page 6: stock plugins on WebUI. Stubbed: until webui-packages ships its
/// packages the demo depends on none of them, so every row says
/// "unavailable here" and what will close it.
class PluginsPage extends StatelessWidget {
  const PluginsPage({super.key, this.host});

  /// The host to report on; [WebUi.host] when null.
  final WebUiHost? host;

  @override
  Widget build(BuildContext context) {
    final h = host ?? WebUi.host;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'An app keeps calling the stock plugins; on WebUI a *_webui package '
            'from webui-packages answers them. None has shipped yet, so this page '
            'shows what each will use. Running in: '
            '${h.isWebUi ? 'a WebUI host' : 'a browser tab'}.',
          ),
        ),
        for (final p in plannedPlugins)
          Section(
            title: p.plugin,
            subtitle: 'On WebUI: ${p.webui}',
            child: Fallback(
              'Unavailable here: the demo does not depend on ${p.plugin} until '
              '${p.plugin}_webui ships.'
              '${p.inBrowser == null ? '' : ' In a browser tab the stock web implementation would use ${p.inBrowser}.'}',
            ),
          ),
      ],
    );
  }
}
