import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/common/seo_head.dart';
import '../components/layout/doc_layout.dart';
import '../components/layout/nav_drawer_scope.dart';
import '../components/layout/sidebar.dart';
import '../components/layout/table_of_contents.dart';
import '../components/markdown/doc_content.dart';
import '../l10n/l10n_provider.dart';
import '../models/doc_id.dart';
import '../routes/app_paths.dart';
import '../components/common/app_link.dart';

/// Generic documentation page. [intro] is an optional slot rendered
/// between the title and the body (optional; no page uses it today).
class DocDetailPage extends StatelessComponent {
  const DocDetailPage({required this.id, this.intro, super.key});

  final DocId id;
  final Component? intro;

  @override
  Component build(BuildContext context) {
    final docs = context.docs;
    final l10n = context.l10n;
    final page = docs.page(id);

    return .fragment([
      SeoHead(title: page.title, description: page.description, path: AppPaths.doc(id)),
      DocLayout(
        sidebar: Sidebar(groups: docs.navigation, activeId: id, onNavigate: NavDrawerScope.of(context).onClose),
        toc: TableOfContents(pageId: id, headings: page.toc),
        child: .fragment([
          p(classes: 'doc-eyebrow', [.text(l10n.docGroup(id.group))]),
          h1(classes: 'doc-title', [.text(page.title)]),
          p(classes: 'doc-lead', [.text(page.description)]),
          ?intro,
          div(classes: 'prose', [DocContent(page.blocks, pageId: id)]),
          _pager(context),
        ]),
      ),
    ]);
  }

  Component _pager(BuildContext context) {
    final l10n = context.l10n;
    final docs = context.docs;
    Component cell(DocId? target, String label, String modifier) {
      if (target == null) return const div(classes: 'pager__spacer', []);
      return AppLink(
        to: AppPaths.doc(target),
        classes: 'pager__link pager__link--$modifier',
        children: [
          span(classes: 'pager__label', [.text(label)]),
          span(classes: 'pager__title', [.text(docs.page(target).title)]),
        ],
      );
    }

    return nav(
      classes: 'pager',
      attributes: {'aria-label': '${l10n.previousPage} / ${l10n.nextPage}'},
      [cell(id.previous, '← ${l10n.previousPage}', 'prev'), cell(id.next, '${l10n.nextPage} →', 'next')],
    );
  }
}
