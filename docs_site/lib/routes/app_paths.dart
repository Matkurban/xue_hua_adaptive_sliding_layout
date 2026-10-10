import '../models/doc_id.dart';

/// Single source of truth for URLs.
///
/// Route paths are always *relative to the site base*: Jaspr reads
/// `<base href>` on the client, strips it from the location before routing
/// and prefixes it in `Link`. The base is set at compile time:
///
/// ```bash
/// jaspr build --dart-define=SITE_BASE=/xue_hua_adaptive_sliding_layout/docs
/// ```
///
/// * no `SITE_BASE` (local dev): home `/`, pages `/docs/<slug>`
/// * `SITE_BASE=/repo/docs`:     home `/repo/docs/`, pages `/repo/docs/<slug>`
///   (the `/docs` segment is already part of the base, so it is not repeated)
abstract final class AppPaths {
  /// Deployment sub-path without trailing slash, e.g. `/repo/docs`. Empty = root.
  static const String base = String.fromEnvironment('SITE_BASE');

  /// Value for `<base href>`.
  static const String baseHref = '$base/';

  static const String home = '/';

  /// The Flutter web demo deployed next to the docs.
  static const String liveDemoUrl = 'https://matkurban.github.io/xue_hua_adaptive_sliding_layout/example/';

  /// Route prefix of doc pages.
  static const String docsRoot = base == '' ? '/docs' : '';

  static String doc(DocId id) => '$docsRoot/${id.slug}';

  static bool isDocPath(String location) => DocId.values.any((id) => doc(id) == location);

  /// href for a plain `<a>` (not `Link`): made relative so the browser
  /// resolves it against `<base href>` identically on server and client.
  static String relative(String routePath) => routePath.startsWith('/') ? routePath.substring(1) : routePath;

  static String anchor(DocId id, String anchor) => '${relative(doc(id))}#$anchor';

  /// Absolute path including the deployment base (canonical / OpenGraph URLs).
  static String absolute(String routePath) => routePath == home ? baseHref : '$base$routePath';
}
