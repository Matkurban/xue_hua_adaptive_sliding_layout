import 'browser_bridge_stub.dart' if (dart.library.js_interop) 'browser_bridge_web.dart' as impl;

/// Thin, mockable facade over the browser APIs the site needs.
/// Every method is a safe no-op during server pre-rendering.
abstract final class BrowserBridge {
  /// Sets (or removes, when [value] is null) an attribute on `<html>`.
  static void setRootAttribute(String name, String? value) => impl.setRootAttribute(name, value);

  /// Copies [text] to the clipboard. Resolves to `false` on failure.
  static Future<bool> copyToClipboard(String text) => impl.copyToClipboard(text);

  /// Scroll lock while the mobile drawer is open.
  static void setBodyScrollLocked(bool locked) => impl.setBodyScrollLocked(locked);
}
