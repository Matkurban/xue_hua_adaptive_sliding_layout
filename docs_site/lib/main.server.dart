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
        // Every icon is rendered from web/favicon.svg — the same mark as the header logo.
        const link(rel: 'icon', href: 'favicon.ico', attributes: {'sizes': '16x16 32x32 48x48'}),
        const link(rel: 'icon', href: 'favicon.svg', type: 'image/svg+xml'),
        const link(rel: 'icon', href: 'favicon-32x32.png', type: 'image/png', attributes: {'sizes': '32x32'}),
        const link(rel: 'icon', href: 'favicon-16x16.png', type: 'image/png', attributes: {'sizes': '16x16'}),
        const link(rel: 'apple-touch-icon', href: 'apple-touch-icon.png'),
        Component.element(tag: 'style', children: [RawText(appCss)]),
      ],
      body: const App(),
    ),
  );
}
