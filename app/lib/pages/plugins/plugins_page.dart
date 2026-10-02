import 'package:demo_core/demo_core.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.copy = _copy,
    this.paste = _paste,
    this.pickFile = _pickFile,
  });

  final Future<String> Function(String text) share;
  final Future<String> Function() cameraStatus;
  final Future<String> Function() requestCamera;

  /// Puts [text] on the clipboard.
  final Future<void> Function(String text) copy;

  /// The clipboard's text, or null when it holds none.
  final Future<String?> Function() paste;

  /// The picked file's path, or null when the pick was cancelled.
  final Future<String?> Function() pickFile;

  static Future<String> _share(String text) async =>
      (await SharePlus.instance.share(ShareParams(text: text))).status.name;
  static Future<String> _cameraStatus() async =>
      (await Permission.camera.status).name;
  static Future<String> _requestCamera() async =>
      (await Permission.camera.request()).name;
  static Future<void> _copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
  static Future<String?> _paste() async =>
      (await Clipboard.getData(Clipboard.kTextPlain))?.text;
  static Future<String?> _pickFile() async => (await openFile())?.path;
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

const clipboardRow = PluginRow(
  'Clipboard (flutter/services)',
  'clipboard_webui: Android\'s clipboard, through the module\'s own app',
  inBrowser: 'the browser\'s clipboard',
);

const fileRow = PluginRow(
  'file_selector',
  'file_selector_webui: the WebView\'s file chooser',
  inBrowser: 'the browser\'s file chooser',
);

/// The other webui-packages plugins, which the demo does not call.
const otherPlugins = [
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
  static const copyText = 'Copied from the p0g demo (page 6).';
  static const unavailable = 'unavailable here (no plugin for this platform)';

  String? _share;
  String? _camera;
  String? _copied;
  String? _pasted;
  String? _picked;
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
    } on MissingPluginException {
      // The Flutter convention where a plugin has no implementation for
      // this platform (permission_handler on AERA or Linux desktop): the
      // capability is not there, which is not an error.
      result = unavailable;
      _log.info('$what: no implementation on this platform');
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
            'The app calls share_plus, permission_handler, the clipboard and '
            'file_selector as on any '
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
          title: clipboardRow.plugin,
          subtitle: webui
              ? 'On WebUI: ${clipboardRow.webui}'
              : 'Here: ${clipboardRow.inBrowser}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run('copy', () async {
                            await widget.calls.copy(copyText);
                            return 'copied';
                          }, (r) => _copied = r),
                    child: const Text('Copy text'),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            'paste',
                            () async =>
                                await widget.calls.paste() ?? '(no text)',
                            (r) => _pasted = r,
                          ),
                    child: const Text('Paste'),
                  ),
                ],
              ),
              if (_copied != null) Text('Copy: $_copied'),
              if (_pasted != null) Text('Pasted: $_pasted'),
            ],
          ),
        ),
        Section(
          title: fileRow.plugin,
          subtitle: webui
              ? 'On WebUI: ${fileRow.webui}'
              : 'Here: ${fileRow.inBrowser}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run(
                        'pick',
                        () async =>
                            await widget.calls.pickFile() ?? '(cancelled)',
                        (r) => _picked = r,
                      ),
                child: const Text('Pick a file'),
              ),
              if (_picked != null) Text('Picked: $_picked'),
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
