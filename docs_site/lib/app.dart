import 'package:jaspr/jaspr.dart';

import 'l10n/l10n_provider.dart';
import 'routes/app_router.dart';
import 'styles/theme_provider.dart';

/// Root component. `@client` makes it pre-rendered on the server *and*
/// hydrated in the browser, so all state (locale, theme, drawer) survives
/// client-side navigation.
@client
class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return const L10nProvider(child: ThemeProvider(child: AppRouter()));
  }
}
