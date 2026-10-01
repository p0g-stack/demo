import 'package:flutter_webui_client/flutter_webui_client.dart';
import 'package:flutter_webui_client/testing.dart';

/// One shell basic: what Flutter calls it, what this host gives for it, and
/// what the app gets when the host gives nothing.
final class ShellRow {
  const ShellRow(this.feature, this.host, {this.fallback});

  /// The Flutter-side name (`MediaQuery.viewPadding`, `SystemNavigator.pop`).
  final String feature;

  /// What the host provides, in its own terms.
  final String host;

  /// Set when the host provides nothing and the browser behaviour stands.
  final String? fallback;
}

/// What [host] gives each shell basic, the way flutter_webui's embedding
/// maps it (its table: insets, lifecycle, back, exit, brightness). The
/// embedding probes methods, so this does too; no manager names.
List<ShellRow> shellReport(WebUiHost host, {Insets? insets, bool? dark}) {
  final ksu = host.ksuMethods;
  final wx = host.kind == WebUiHostKind.webuix;
  if (!host.isWebUi) {
    const tab = 'browser tab';
    return const [
      ShellRow(
        'MediaQuery.viewPadding',
        tab,
        fallback: 'zero: a tab has no system bars',
      ),
      ShellRow(
        'MediaQuery.viewInsets',
        tab,
        fallback: 'the browser resizes the page for the keyboard',
      ),
      ShellRow('AppLifecycleState', tab, fallback: 'page visibility'),
      ShellRow('Back', tab, fallback: 'browser history'),
      ShellRow(
        'SystemNavigator.pop',
        tab,
        fallback: 'nothing: a tab cannot close itself',
      ),
      ShellRow('platformBrightness', tab, fallback: 'prefers-color-scheme'),
    ];
  }
  final edge = ksu.contains('enableEdgeToEdge')
      ? 'ksu.enableEdgeToEdge(true)'
      : ksu.contains('enableInsets')
      ? 'ksu.enableInsets(true)'
      : null;
  final insetsText = insets == null
      ? null
      : 'top ${_n(insets.top)}, bottom ${_n(insets.bottom)}';
  return [
    ShellRow(
      'MediaQuery.viewPadding',
      [
        ?edge,
        if (wx) 'WX_ON_INSETS',
        if (insetsText != null) 'insets.css: $insetsText',
      ].join('; '),
      fallback: edge == null && !wx
          ? 'no edge-to-edge call: the manager keeps its bars, padding zero'
          : insetsText == null
          ? 'no insets reported yet: padding zero'
          : null,
    ),
    const ShellRow(
      'MediaQuery.viewInsets',
      'WebView resize',
      fallback: 'the WebView resizes for the keyboard, as a browser does',
    ),
    ShellRow(
      'AppLifecycleState',
      wx ? 'WX_ON_PAUSE / WX_ON_RESUME' : 'page visibility',
    ),
    ShellRow(
      'Back',
      wx ? 'WX_ON_BACK, then history.back()' : 'WebView history',
    ),
    ShellRow(
      'SystemNavigator.pop',
      ksu.contains('exit')
          ? 'ksu.exit()'
          : host.webuiMethods.contains('exit')
          ? 'webui.exit()'
          : 'no exit method',
      fallback: host.canExit
          ? null
          : 'history unwinds; the manager\'s own Back closes the page',
    ),
    ShellRow(
      'platformBrightness',
      wx && host.moduleGlobal != null
          ? '${host.moduleGlobal}.isDarkMode() = ${dark ?? 'not answered'}'
          : 'prefers-color-scheme',
      fallback: wx && dark == null ? 'prefers-color-scheme' : null,
    ),
  ];
}

String _n(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

/// A host profile from flutter_webui_client's fakes (its docs/hosts.md).
final class FakeHost {
  const FakeHost(this.label, this.bridge);

  final String label;
  final FakeBridge Function() bridge;

  WebUiHost get host => WebUiHost.detect(bridge());

  List<ShellRow> get report {
    final b = bridge();
    return shellReport(WebUiHost.detect(b), insets: b.insets, dark: b.darkMode);
  }
}

final fakeHosts = <FakeHost>[
  FakeHost('Browser tab', FakeBridge.browser),
  FakeHost('KernelSU', FakeBridge.kernelsu),
  FakeHost('KernelSU Next', FakeBridge.next),
  FakeHost('APatch', FakeBridge.apatch),
  FakeHost('WebUI X', FakeBridge.webuix),
];
