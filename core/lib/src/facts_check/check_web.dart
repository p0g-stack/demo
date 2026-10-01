import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../facts.dart';

/// A browser page or Web Worker: no root, devices or processes; feature
/// checks for the rest.
Future<Map<String, Object?>> checkFacts() async {
  final nav = globalContext['navigator'] as JSObject?;
  final storage = nav?['storage'] as JSObject?;
  return {
    Fact.root: false,
    Fact.blockDevices: false,
    Fact.usbNative: false,
    Fact.usbWeb: nav != null && nav.has('usb'),
    Fact.processSpawn: false,
    Fact.fsPersistent: storage != null && storage.has('getDirectory'),
    Fact.net: nav?['onLine']?.dartify() == true,
  };
}
