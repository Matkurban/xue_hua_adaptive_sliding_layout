import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/theme_preference.dart';
import '../../styles/theme_provider.dart';

/// Cycles system → light → dark.
class ThemeToggle extends StatelessComponent {
  const ThemeToggle({super.key});

  static String _icon(ThemePreference p) => switch (p) {
    ThemePreference.system => '🖥',
    ThemePreference.light => '☀',
    ThemePreference.dark => '☾',
  };

  @override
  Component build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;
    final current = theme.preference;
    final label = '${l10n.toggleTheme}: ${l10n.themeName(current)}';
    return button(
      classes: 'icon-button theme-toggle',
      type: ButtonType.button,
      attributes: {'aria-label': label, 'title': label},
      onClick: () => theme.setPreference(current.next),
      [
        span(attributes: {'aria-hidden': 'true'}, [.text(_icon(current))]),
      ],
    );
  }
}
