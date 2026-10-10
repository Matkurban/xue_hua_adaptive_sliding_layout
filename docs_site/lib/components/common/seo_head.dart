import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../l10n/l10n_provider.dart';
import '../../routes/app_paths.dart';

/// Per-page `<title>`, description and OpenGraph/Twitter meta via
/// `Document.head` (rendered at build time, updated on client navigation).
class SeoHead extends StatelessComponent {
  const SeoHead({required this.title, required this.description, required this.path, super.key});

  final String title;
  final String description;
  final String path;

  /// Configure for your deployment domain.
  static const String siteOrigin = String.fromEnvironment('SITE_ORIGIN', defaultValue: 'https://matkurban.github.io');

  @override
  Component build(BuildContext context) {
    final l10n = context.l10n;
    final fullTitle = title == l10n.siteName ? title : '$title | ${l10n.siteName}';
    final url = '$siteOrigin${AppPaths.absolute(path)}';
    return Document.head(
      title: fullTitle,
      children: [
        meta(name: 'description', content: description),
        const meta(attributes: {'property': 'og:type'}, content: 'website'),
        meta(attributes: {'property': 'og:site_name'}, content: l10n.siteName),
        meta(attributes: {'property': 'og:title'}, content: fullTitle),
        meta(attributes: {'property': 'og:description'}, content: description),
        meta(attributes: {'property': 'og:url'}, content: url),
        meta(attributes: {'property': 'og:locale'}, content: l10n.locale.tag.replaceAll('-', '_')),
        const meta(name: 'twitter:card', content: 'summary'),
        link(rel: 'canonical', href: url),
      ],
    );
  }
}
