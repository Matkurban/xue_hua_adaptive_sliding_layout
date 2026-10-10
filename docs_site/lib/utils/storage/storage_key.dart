/// All persisted keys live here — no ad-hoc string keys elsewhere.
enum StorageKey {
  locale('xh_docs.locale'),
  theme('xh_docs.theme');

  const StorageKey(this.key);
  final String key;
}
