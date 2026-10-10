/// Server / pre-rendering entrypoint (static mode → SSG at build time).
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'app.dart';
import 'main.server.options.dart';
import 'models/app_locale.dart';
import 'routes/app_paths.dart';
import 'styles/app_styles.dart';
import 'styles/theme_provider.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(
    Document(
      lang: AppLocale.fallback.tag,
      base: AppPaths.baseHref,
      viewport: 'width=device-width, initial-scale=1',
      meta: {'color-scheme': 'light dark', 'theme-color': '#0b6bcb'},
      head: [
        // Must run before first paint to avoid a theme flash.
        script(content: themeBootScript),
        const link(rel: 'icon', href: 'favicon.ico'),
        Component.element(tag: 'style', children: [RawText(appCss)]),
      ],
      body: const App(),
    ),
  );
}
