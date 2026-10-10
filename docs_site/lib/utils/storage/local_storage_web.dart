import 'package:universal_web/web.dart' as web;

import 'local_storage.dart';

KeyValueStore createStore() => _BrowserStore();

class _BrowserStore implements KeyValueStore {
  @override
  String? read(StorageKey key) {
    try {
      return web.window.localStorage.getItem(key.key);
    } catch (_) {
      return null;
    }
  }

  @override
  void write(StorageKey key, String value) {
    try {
      web.window.localStorage.setItem(key.key, value);
    } catch (_) {
      // Storage may be unavailable (private mode, quota) — degrade gracefully.
    }
  }
}
