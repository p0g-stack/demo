import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'facts.dart';

Future<Facts> probe(String? as) async {
  final g = globalContext;
  final inPage = g.has('document');
  final nav = g['navigator'] as JSObject?;
  final storage = nav?['storage'] as JSObject?;
  final opfs = storage != null && storage.has('getDirectory');
  final usb = nav != null && nav.has('usb');
  final online = nav?['onLine']?.dartify() == true;

  return Facts(
    runtime: as ?? (inPage ? 'browser page' : 'web worker'),
    values: {
      Fact.root: false,
      Fact.blockDevices: false,
      Fact.usbNative: false,
      Fact.usbWeb: usb,
      Fact.processSpawn: false,
      Fact.fsPersistent: opfs,
      Fact.net: online,
    },
    notes: {
      Fact.root: 'browser sandbox',
      Fact.blockDevices: 'browser sandbox',
      Fact.usbNative: 'browser sandbox',
      Fact.usbWeb: usb ? 'navigator.usb present' : 'no navigator.usb',
      Fact.processSpawn: 'browser sandbox',
      Fact.fsPersistent: opfs ? 'OPFS present' : 'no OPFS',
      Fact.net: 'navigator.onLine',
    },
  );
}
