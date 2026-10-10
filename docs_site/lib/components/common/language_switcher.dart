import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/app_locale.dart';

/// Segmented control; switching rebuilds only dependents of the L10n scope
/// (no page reload, no route change).
class LanguageSwitcher extends StatelessComponent {
  const LanguageSwitcher({super.key});

  @override
  Component build(BuildContext context) {
    final controller = context.l10nController;
    return div(
      classes: 'segmented',
      attributes: {'role': 'group', 'aria-label': context.l10n.languageLabel},
      [
        for (final locale in AppLocale.values)
          button(
            classes: 'segmented__item${locale == controller.locale ? ' is-active' : ''}',
            type: ButtonType.button,
            attributes: {'aria-pressed': '${locale == controller.locale}', 'lang': locale.tag},
            onClick: () => controller.setLocale(locale),
            [.text(locale == AppLocale.en ? 'EN' : '中文')],
          ),
      ],
    );
  }
}
