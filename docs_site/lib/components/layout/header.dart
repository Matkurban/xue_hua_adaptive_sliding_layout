import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/doc_id.dart';
import '../../routes/app_paths.dart';
import '../common/language_switcher.dart';
import '../common/theme_toggle.dart';
import 'nav_drawer_scope.dart';
import 'responsive_container.dart';
import '../common/app_link.dart';

class Header extends StatelessComponent {
  const Header({required this.location, super.key});

  final String location;

  static const githubUrl = 'https://github.com/Matkurban/xue_hua_adaptive_sliding_layout';

  @override
  Component build(BuildContext context) {
    final l10n = context.l10n;
    final drawer = NavDrawerScope.of(context);
    final inDocs = AppPaths.isDocPath(location);

    return header(classes: 'site-header', [
      ResponsiveContainer(
        classes: 'site-header__inner',
        child: .fragment([
          if (inDocs)
            button(
              classes: 'icon-button site-header__menu',
              type: ButtonType.button,
              attributes: {
                'aria-label': drawer.isOpen ? l10n.closeMenu : l10n.openMenu,
                'aria-expanded': '${drawer.isOpen}',
                'aria-controls': 'doc-sidebar',
              },
              onClick: drawer.onToggle,
              [.text(drawer.isOpen ? '✕' : '☰')],
            ),
          AppLink(
            to: AppPaths.home,
            classes: 'brand',
            children: [
              const img(classes: 'brand__logo', src: 'favicon.svg', alt: '', width: 24, height: 24),
              span(classes: 'brand__name', [.text(l10n.siteName)]),
            ],
          ),
          nav(
            classes: 'site-header__nav',
            attributes: {'aria-label': 'Primary'},
            [
              AppLink(
                to: AppPaths.home,
                classes: location == AppPaths.home ? 'is-active' : null,
                child: .text(l10n.navHome),
              ),
              AppLink(
                to: AppPaths.doc(DocId.introduction),
                classes: inDocs ? 'is-active' : null,
                child: .text(l10n.navDocs),
              ),
              a(href: githubUrl, target: Target.blank, attributes: {'rel': 'noopener'}, [.text(l10n.navGithub)]),
            ],
          ),
          const div(classes: 'site-header__actions', [LanguageSwitcher(), ThemeToggle()]),
        ]),
      ),
    ]);
  }
}
