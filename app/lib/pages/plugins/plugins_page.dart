import 'package:demo_core/demo_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webui_client/flutter_webui_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../common/facts_view.dart';

/// The calls page 6 makes, through the stock plugins unless a test swaps
/// them. Each returns what the plugin answered, as text.
final class PluginCalls {
  const PluginCalls({
    this.share = _share,
    this.cameraStatus = _cameraStatus,
    this.requestCamera = _requestCamera,
  });

  final Future<String> Function(String text) share;
  final Future<String> Function() cameraStatus;
  final Future<String> Function() requestCamera;

  static Future<String> _share(String text) async =>
      (await SharePlus.instance.share(ShareParams(text: text))).status.name;
  static Future<String> _cameraStatus() async =>
      (await Permission.camera.status).name;
  static Future<String> _requestCamera() async =>
      (await Permission.camera.request()).name;
}

/// A stock plugin and how webui-packages answers it on WebUI.
final class PluginRow {
  const PluginRow(this.plugin, this.webui, {this.inBrowser});

  /// The pub package an app depends on.
  final String plugin;

  /// The route on WebUI (webui-packages' table).
  final String webui;

  /// What the stock web implementation does in a browser tab.
  final String? inBrowser;
}

const shareRow = PluginRow(
  'share_plus',
  'share_plus_webui: Android\'s share sheet, opened by the module\'s own app',
  inBrowser: 'the Web Share API where the browser has it',
);

const cameraRow = PluginRow(
  'permission_handler',
  'permission_handler_webui: Android\'s own permission dialog, for the '
      'module\'s own app',
  inBrowser: 'the browser\'s camera prompt',
);

/// The other webui-packages plugins, which the demo does not call.
const otherPlugins = [
  PluginRow('file_selector', 'file_selector_webui: WebView chooser'),
  PluginRow('url_launcher', 'url_launcher_webui: start an activity'),
  PluginRow('path_provider', 'path_provider_webui: module and state dirs'),
  PluginRow('shared_preferences', 'shared_preferences_webui: module storage'),
];

/// Page 6: stock plugins, called unchanged. On WebUI flutter_p0g builds in
/// the `*_webui` package for each, which answers through the module's own
/// Android app (the app plane); in a browser tab the stock web one answers.
class PluginsPage extends StatefulWidget {
  const PluginsPage({super.key, this.host, this.calls = const PluginCalls()});

  /// The host to report on; [WebUi.host] when null.
  final WebUiHost? host;

  final PluginCalls calls;

  @override
  State<PluginsPage> createState() => _PluginsPageState();
}

class _PluginsPageState extends State<PluginsPage> {
  static final _log = Logger('ui.plugins');
  static const shareText = 'Shared from the p0g demo (page 6).';

  String? _share;
  String? _camera;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _run('camera status', widget.calls.cameraStatus, (r) => _camera = r);
  }

  Future<void> _run(
    String what,
    Future<String> Function() call,
    void Function(String) set,
  ) async {
    setState(() => _busy = true);
    String result;
    try {
      result = await call();
      _log.info('$what: $result');
    } catch (e) {
      result = 'failed: $e';
      _log.warning('$what failed', e);
    }
    if (!mounted) return;
    setState(() {
      set(result);
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.host ?? WebUi.host;
    final webui = h.isWebUi;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'The app calls share_plus and permission_handler as on any '
            'platform. Running in ${webui ? 'a WebUI host' : 'a browser tab'}, '
            'so ${webui ? 'their *_webui packages' : 'the stock web packages'} '
            'answer.',
          ),
        ),
        Section(
          title: shareRow.plugin,
          subtitle: webui
              ? 'On WebUI: ${shareRow.webui}'
              : 'Here: ${shareRow.inBrowser}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run(
                        'share',
                        () => widget.calls.share(shareText),
                        (r) => _share = r,
                      ),
                child: const Text('Share text'),
              ),
              if (_share != null) Text('Share result: $_share'),
            ],
          ),
        ),
        Section(
          title: cameraRow.plugin,
          subtitle: webui
              ? 'On WebUI: ${cameraRow.webui}'
              : 'Here: ${cameraRow.inBrowser}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Camera: ${_camera ?? 'checking...'}'),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run(
                        'camera request',
                        widget.calls.requestCamera,
                        (r) => _camera = r,
                      ),
                child: const Text('Request camera'),
              ),
            ],
          ),
        ),
        Section(
          title: 'Not called here',
          subtitle: 'The other webui-packages plugins.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final p in otherPlugins) Text('${p.plugin}: ${p.webui}'),
            ],
          ),
        ),
      ],
    );
  }
}
