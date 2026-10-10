import 'storage_key.dart';
import 'local_storage_stub.dart' if (dart.library.js_interop) 'local_storage_web.dart' as impl;

export 'storage_key.dart';

/// Platform-agnostic key/value persistence.
///
/// On the server (pre-rendering) this is a no-op store, so components can
/// call it unconditionally; on the web it is backed by `window.localStorage`
/// and silently tolerates private-mode / quota errors.
abstract interface class KeyValueStore {
  String? read(StorageKey key);
  void write(StorageKey key, String value);

  static final KeyValueStore instance = impl.createStore();
}
