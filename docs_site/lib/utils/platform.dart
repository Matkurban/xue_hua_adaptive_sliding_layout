import 'package:jaspr/jaspr.dart' show kIsWeb;

/// Platform helpers. `kIsWeb` is a compile-time constant, so server-only
/// branches are tree-shaken from the client bundle and vice versa.
abstract final class Platform {
  static const bool isBrowser = kIsWeb;
  static const bool isServer = !kIsWeb;
}
