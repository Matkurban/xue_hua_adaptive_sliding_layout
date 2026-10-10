import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../l10n/l10n_provider.dart';
import 'nav_drawer_scope.dart';

/// Three-column documentation skeleton built purely from slots:
///
/// ```
/// ┌──────────┬──────────────────┬────────┐
/// │ sidebar  │      child       │  toc   │   ≥ 1200px
/// ├──────────┼──────────────────┴────────┤
/// │ sidebar  │      child (toc hidden)   │   ≥ 900px
/// ├──────────┴───────────────────────────┤
/// │ child; sidebar becomes a drawer       │   < 900px
/// └──────────────────────────────────────┘
/// ```
class DocLayout extends StatelessComponent {
  const DocLayout({required this.sidebar, required this.child, this.toc, super.key});

  final Component sidebar;
  final Component child;
  final Component? toc;

  @override
  Component build(BuildContext context) {
    final drawer = NavDrawerScope.of(context);
    return div(classes: 'doc-layout${drawer.isOpen ? ' is-drawer-open' : ''}', [
      div(
        classes: 'doc-layout__backdrop',
        attributes: {'aria-hidden': 'true', 'title': context.l10n.closeMenu},
        events: {'click': (_) => drawer.onClose()},
        [],
      ),
      aside(id: 'doc-sidebar', classes: 'doc-layout__sidebar', [sidebar]),
      article(classes: 'doc-layout__content', [child]),
      if (toc case final toc?) aside(classes: 'doc-layout__toc', [toc]),
    ]);
  }
}
