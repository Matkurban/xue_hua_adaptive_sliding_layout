import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../l10n/l10n_provider.dart';
import 'responsive_container.dart';

class Footer extends StatelessComponent {
  const Footer({super.key});

  /// Fixed at build time so server and client render identical text.
  static const int _year = 2026;

  @override
  Component build(BuildContext context) {
    final l10n = context.l10n;
    return footer(classes: 'site-footer', [
      ResponsiveContainer(
        classes: 'site-footer__inner',
        child: .fragment([
          span([.text(l10n.footerCopyright(_year))]),
          a(
            href: 'https://jaspr.site',
            target: Target.blank,
            attributes: {'rel': 'noopener'},
            [.text(l10n.footerBuiltWith)],
          ),
        ]),
      ),
    ]);
  }
}
