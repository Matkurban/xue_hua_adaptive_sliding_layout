import 'dart:js_interop';

import 'package:universal_web/web.dart' as web;

void setRootAttribute(String name, String? value) {
  final root = web.document.documentElement;
  if (root == null) return;
  if (value == null) {
    root.removeAttribute(name);
  } else {
    root.setAttribute(name, value);
  }
}

Future<bool> copyToClipboard(String text) async {
  try {
    await web.window.navigator.clipboard.writeText(text).toDart;
    return true;
  } catch (_) {
    return _legacyCopy(text);
  }
}

/// Fallback for non-secure contexts (http on LAN) where the async
/// Clipboard API is unavailable.
bool _legacyCopy(String text) {
  try {
    final area = web.document.createElement('textarea') as web.HTMLTextAreaElement
      ..value = text
      ..style.position = 'fixed'
      ..style.opacity = '0';
    web.document.body?.append(area);
    area.select();
    final ok = web.document.execCommand('copy');
    area.remove();
    return ok;
  } catch (_) {
    return false;
  }
}

void setBodyScrollLocked(bool locked) {
  web.document.body?.style.overflow = locked ? 'hidden' : '';
}
