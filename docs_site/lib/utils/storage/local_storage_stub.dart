import 'local_storage.dart';

KeyValueStore createStore() => _NoopStore();

class _NoopStore implements KeyValueStore {
  @override
  String? read(StorageKey key) => null;

  @override
  void write(StorageKey key, String value) {}
}
