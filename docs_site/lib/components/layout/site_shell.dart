import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../l10n/l10n_provider.dart';
import '../../routes/app_paths.dart';
import '../../utils/browser/browser_bridge.dart';
import 'footer.dart';
import 'header.dart';
import 'nav_drawer_scope.dart';

/// Global page skeleton: header / main slot / footer.
class SiteShell extends StatefulComponent {
  const SiteShell({required this.location, required this.child, super.key});

  /// Current route path (relative to the site base).
  final String location;
  final Component child;

  @override
  State<SiteShell> createState() => _SiteShellState();
}

class _SiteShellState extends State<SiteShell> {
  bool _drawerOpen = false;

  void _setDrawer(bool open) {
    if (open == _drawerOpen) return;
    setState(() => _drawerOpen = open);
    BrowserBridge.setBodyScrollLocked(open);
  }

  @override
  Component build(BuildContext context) {
    return NavDrawerScope(
      isOpen: _drawerOpen,
      onToggle: () => _setDrawer(!_drawerOpen),
      onClose: () => _setDrawer(false),
      child: div(classes: 'site', [
        a(href: '${AppPaths.relative(component.location)}#main-content', classes: 'skip-link', [
          .text(context.l10n.skipToContent),
        ]),
        Header(location: component.location),
        main_(id: 'main-content', classes: 'site__main', [component.child]),
        const Footer(),
      ]),
    );
  }
}
