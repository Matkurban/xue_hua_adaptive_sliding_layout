import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/code/code_block.dart';
import '../components/common/seo_head.dart';
import '../components/layout/responsive_container.dart';
import '../l10n/l10n_provider.dart';
import '../models/doc_id.dart';
import '../models/doc_page.dart';
import '../routes/app_paths.dart';
import '../components/common/app_link.dart';

class HomePage extends StatelessComponent {
  const HomePage({super.key});

  static const _snippet = '''
final router = AdaptiveRouter.of(context);
router.pushNamed('/mail/inbox');
router.pushNamed(
  router.namedLocation('thread',
      pathParameters: {'folder': 'inbox', 'threadId': '42'}),
  arguments: thread,
);
router.pop();''';

  @override
  Component build(BuildContext context) {
    final l10n = context.l10n;
    return .fragment([
      SeoHead(title: l10n.siteName, description: l10n.siteDescription, path: AppPaths.home),
      section(classes: 'hero', [
        ResponsiveContainer(
          classes: 'hero__inner',
          child: .fragment([
            div(classes: 'hero__text', [
              span(classes: 'badge', [.text(l10n.homeHeroBadge)]),
              h1(classes: 'hero__title', [.text(l10n.homeHeroTitle)]),
              p(classes: 'hero__subtitle', [.text(l10n.homeHeroSubtitle)]),
              div(classes: 'hero__actions', [
                AppLink(
                  to: AppPaths.doc(DocId.introduction),
                  classes: 'btn btn--primary',
                  child: .text(l10n.homeCtaPrimary),
                ),
                a(
                  href: AppPaths.liveDemoUrl,
                  classes: 'btn btn--ghost',
                  target: Target.blank,
                  attributes: {'rel': 'noopener'},
                  [.text(l10n.homeCtaSecondary)],
                ),
              ]),
            ]),
            const div(classes: 'hero__code', [CodeBlock(code: _snippet, language: CodeLanguage.dart)]),
          ]),
        ),
      ]),
      section(classes: 'features', [
        ResponsiveContainer(
          child: .fragment([
            h2(classes: 'features__title', [.text(l10n.homeFeaturesTitle)]),
            div(classes: 'features__grid', [
              for (final f in l10n.homeFeatures)
                div(classes: 'feature-card', [
                  span(classes: 'feature-card__icon', attributes: {'aria-hidden': 'true'}, [.text(f.icon)]),
                  h3([.text(f.title)]),
                  p([.text(f.body)]),
                ]),
            ]),
          ]),
        ),
      ]),
    ]);
  }
}
