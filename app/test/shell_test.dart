import 'package:demo/pages/plugins/plugins_page.dart';
import 'package:demo/pages/shell/shell_page.dart';
import 'package:demo/pages/shell/shell_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webui_client/flutter_webui_client.dart';
import 'package:flutter_webui_client/testing.dart';

ShellRow row(List<ShellRow> rows, String feature) =>
    rows.firstWhere((r) => r.feature == feature);

List<ShellRow> report(FakeBridge b) =>
    shellReport(WebUiHost.detect(b), insets: b.insets, dark: b.darkMode);

void main() {
  test('a browser tab falls back for everything', () {
    final rows = report(FakeBridge.browser());
    expect(rows.every((r) => r.fallback != null), isTrue);
    expect(row(rows, 'SystemNavigator.pop').fallback, contains('cannot close'));
  });

  test('KernelSU: edge-to-edge, insets and ksu.exit', () {
    final rows = report(FakeBridge.kernelsu());
    final padding = row(rows, 'MediaQuery.viewPadding');
    expect(padding.host, contains('ksu.enableEdgeToEdge(true)'));
    expect(padding.host, contains('top 24, bottom 48'));
    expect(padding.fallback, isNull);
    expect(row(rows, 'SystemNavigator.pop').host, 'ksu.exit()');
  });

  test('KernelSU Next and APatch have no exit, so history unwinds', () {
    for (final b in [FakeBridge.next(), FakeBridge.apatch()]) {
      final pop = row(report(b), 'SystemNavigator.pop');
      expect(pop.host, 'no exit method');
      expect(pop.fallback, contains('Back closes the page'));
    }
    expect(
      row(report(FakeBridge.apatch()), 'MediaQuery.viewPadding').fallback,
      contains('no insets reported'),
    );
  });

  test('WebUI X: events, webui.exit and the module global for dark mode', () {
    final rows = report(FakeBridge.webuix());
    expect(row(rows, 'Back').host, contains('WX_ON_BACK'));
    expect(row(rows, 'SystemNavigator.pop').host, 'webui.exit()');
    expect(
      row(rows, 'platformBrightness').host,
      r'$demo_mod.isDarkMode() = true',
    );
  });

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
  }

  testWidgets('the shell page reports this host and every fake host', (
    tester,
  ) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => calls.add(call.method),
    );
    await pump(tester, const ShellPage());
    expect(find.text('This host: browser tab'), findsOneWidget);
    await tester.tap(find.text('WebUI X'));
    await tester.pump();
    expect(find.text('WebUI X, module demo-mod'), findsOneWidget);
    await tester.tap(find.text('SystemNavigator.pop()'));
    await tester.pumpAndSettle();
    expect(calls, contains('SystemNavigator.pop'));
    expect(find.textContaining('Still here'), findsOneWidget);
  });

  testWidgets('the plugins page shares text and requests the camera', (
    tester,
  ) async {
    final shared = <String>[];
    var camera = 'denied';
    final calls = PluginCalls(
      share: (text) async {
        shared.add(text);
        return 'success';
      },
      cameraStatus: () async => camera,
      requestCamera: () async => camera = 'granted',
    );
    await pump(
      tester,
      PluginsPage(host: WebUiHost.detect(FakeBridge.webuix()), calls: calls),
    );
    await tester.pumpAndSettle();
    expect(find.text('Camera: denied'), findsOneWidget);
    expect(find.textContaining('On WebUI: share_plus_webui'), findsOneWidget);

    await tester.tap(find.text('Share text'));
    await tester.pumpAndSettle();
    expect(shared, hasLength(1));
    expect(find.text('Share result: success'), findsOneWidget);

    await tester.tap(find.text('Request camera'));
    await tester.pumpAndSettle();
    expect(find.text('Camera: granted'), findsOneWidget);
  });

  testWidgets('the plugins page reports a plugin that throws', (tester) async {
    final calls = PluginCalls(
      share: (_) async => throw StateError('no share sheet'),
      cameraStatus: () async => 'denied',
      requestCamera: () async => 'denied',
    );
    await pump(
      tester,
      PluginsPage(host: WebUiHost.detect(FakeBridge.browser()), calls: calls),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Here: the Web Share API'), findsOneWidget);
    await tester.tap(find.text('Share text'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('failed: Bad state: no share sheet'),
      findsOneWidget,
    );
  });

  testWidgets('the plugins page copies, pastes and picks a file', (
    tester,
  ) async {
    String? clipboard;
    final calls = PluginCalls(
      cameraStatus: () async => 'denied',
      copy: (text) async => clipboard = text,
      paste: () async => clipboard,
      pickFile: () async => '/sdcard/Download/a.txt',
    );
    await pump(
      tester,
      PluginsPage(host: WebUiHost.detect(FakeBridge.webuix()), calls: calls),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('On WebUI: clipboard_webui'), findsOneWidget);

    Future<void> tap(String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await tap('Paste');
    expect(find.text('Pasted: (no text)'), findsOneWidget);
    await tap('Copy text');
    await tap('Paste');
    expect(
      find.text('Pasted: Copied from the p0g demo (page 6).'),
      findsOneWidget,
    );
    await tap('Pick a file');
    expect(find.text('Picked: /sdcard/Download/a.txt'), findsOneWidget);
  });

  testWidgets('the plugins page shows a plugin with no implementation as '
      'unavailable', (tester) async {
    Future<String> missing() async =>
        throw MissingPluginException('No implementation found');
    final calls = PluginCalls(cameraStatus: missing, requestCamera: missing);
    await pump(
      tester,
      PluginsPage(host: WebUiHost.detect(FakeBridge.browser()), calls: calls),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Camera: unavailable here (no plugin for this platform)'),
      findsOneWidget,
    );
    expect(find.textContaining('failed'), findsNothing);
  });

  testWidgets('the plugins page shows a notification', (tester) async {
    final shown = <String>[];
    final calls = PluginCalls(
      cameraStatus: () async => 'denied',
      notify: (text) async {
        shown.add(text);
        return 'shown';
      },
    );
    await pump(
      tester,
      PluginsPage(host: WebUiHost.detect(FakeBridge.webuix()), calls: calls),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('On WebUI: flutter_local_notifications_webui'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Show notification'));
    await tester.tap(find.text('Show notification'));
    await tester.pumpAndSettle();
    expect(shown, hasLength(1));
    expect(find.text('Notification: shown'), findsOneWidget);
  });
}
