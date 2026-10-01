import 'dart:js_interop';
import 'dart:js_interop_unsafe';

const _key = 'p0g_demo_lifecycle';

JSObject? get _storage {
  try {
    return globalContext['localStorage'] as JSObject?;
  } on Object {
    return null;
  }
}

String? read() {
  try {
    return (_storage?.callMethod('getItem'.toJS, _key.toJS) as JSString?)
        ?.toDart;
  } on Object {
    return null;
  }
}

void write(String s) {
  try {
    _storage?.callMethod('setItem'.toJS, _key.toJS, s.toJS);
  } on Object {
    // Storage can be off in a WebView; the page still works without it.
  }
}
