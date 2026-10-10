import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/doc_id.dart';
import '../../models/nav_item.dart';
import '../../routes/app_paths.dart';
import '../common/app_link.dart';

/// Collapsible documentation tree with active-page highlight.
class Sidebar extends StatefulComponent {
  const Sidebar({required this.groups, required this.activeId, this.onNavigate, super.key});

  final List<NavGroup> groups;
  final DocId activeId;

  /// Called after a link is clicked (closes the mobile drawer).
  final VoidCallback? onNavigate;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final Set<DocGroup> _collapsed = {};

  void _toggle(DocGroup group) =>
      setState(() => _collapsed.contains(group) ? _collapsed.remove(group) : _collapsed.add(group));

  @override
  Component build(BuildContext context) {
    final l10n = context.l10n;
    return nav(
      classes: 'sidebar',
      attributes: {'aria-label': l10n.navDocs},
      [
        for (final group in component.groups)
          () {
            // A group containing the active page can never be collapsed away.
            final containsActive = group.group == component.activeId.group;
            final expanded = containsActive || !_collapsed.contains(group.group);
            final listId = 'nav-group-${group.group.name}';
            return div(classes: 'sidebar__group${expanded ? ' is-expanded' : ''}', [
              button(
                classes: 'sidebar__group-toggle',
                type: ButtonType.button,
                attributes: {
                  'aria-expanded': '$expanded',
                  'aria-controls': listId,
                  'title': expanded ? l10n.collapseGroup : l10n.expandGroup,
                },
                onClick: () => _toggle(group.group),
                [
                  span([.text(l10n.docGroup(group.group))]),
                  const span(classes: 'sidebar__chevron', attributes: {'aria-hidden': 'true'}, [.text('›')]),
                ],
              ),
              ul(id: listId, classes: 'sidebar__list', [
                for (final item in group.items)
                  li(
                    events: {'click': (_) => component.onNavigate?.call()},
                    [
                      AppLink(
                        to: AppPaths.doc(item.id),
                        classes: item.id == component.activeId ? 'sidebar__link is-active' : 'sidebar__link',
                        attributes: item.id == component.activeId ? {'aria-current': 'page'} : null,
                        child: .text(item.label),
                      ),
                    ],
                  ),
              ]),
            ]);
          }(),
      ],
    );
  }
}
