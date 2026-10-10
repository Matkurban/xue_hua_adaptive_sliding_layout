import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:universal_web/web.dart' as web;

import '../../routes/app_paths.dart';

/// Base-path-safe replacement for jaspr_router's `Link`.
///
/// `Link` prefixes `binding.basePath`, which is the `<base href>` path on the
/// client but `/` during static pre-rendering — so pre-rendered hrefs would
/// miss the deployment sub-path (`/repo/docs`). `AppLink` instead renders a
/// *relative* href (`quick-start`, `./`) that the browser resolves against
/// `<base href>` identically on server and client, and still performs
/// client-side navigation on plain left-clicks.
class AppLink extends StatelessComponent {
  const AppLink({required this.to, this.classes, this.attributes, this.child, this.children, super.key});

  /// Route path relative to the site base, e.g. `AppPaths.doc(DocId.faq)`.
  final String to;
  final String? classes;
  final Map<String, String>? attributes;
  final Component? child;
  final List<Component>? children;

  @override
  Component build(BuildContext context) {
    return a(
      href: to == AppPaths.home ? './' : AppPaths.relative(to),
      classes: classes,
      attributes: attributes,
      events: {
        'click': (event) {
          final router = Router.maybeOf(context);
          if (router == null) return;
          final mouse = event as web.MouseEvent; // click events are always MouseEvents
          if (mouse.button != 0 || mouse.metaKey || mouse.ctrlKey || mouse.shiftKey || mouse.altKey) {
            return; // let the browser open new tabs/windows
          }
          event.preventDefault();
          router.push(to);
        },
      },
      [?child, ...?children],
    );
  }
}
