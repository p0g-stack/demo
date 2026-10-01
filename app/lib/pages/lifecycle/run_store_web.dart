import 'package:web/web.dart' as web;

const _key = 'p0g_demo_lifecycle';

String? read() {
  try {
    return web.window.localStorage.getItem(_key);
  } on Object {
    return null;
  }
}

void write(String s) {
  try {
    web.window.localStorage.setItem(_key, s);
  } on Object {
    // Storage can be off in a WebView; the page still works without it.
  }
}
