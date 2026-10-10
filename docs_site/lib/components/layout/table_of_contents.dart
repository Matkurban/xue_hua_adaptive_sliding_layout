import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/doc_id.dart';
import '../../models/doc_page.dart';
import '../../routes/app_paths.dart';

/// Right-hand "On this page" anchor list, derived from page headings.
class TableOfContents extends StatelessComponent {
  const TableOfContents({required this.pageId, required this.headings, super.key});

  final DocId pageId;
  final List<DocHeading> headings;

  @override
  Component build(BuildContext context) {
    if (headings.isEmpty) return const .fragment([]);
    return nav(
      classes: 'toc',
      attributes: {'aria-label': context.l10n.onThisPage},
      [
        p(classes: 'toc__title', [.text(context.l10n.onThisPage)]),
        ul([
          for (final h in headings)
            li(classes: 'toc__item toc__item--h${h.level}', [
              a(href: AppPaths.anchor(pageId, h.anchor), [.text(h.text)]),
            ]),
        ]),
      ],
    );
  }
}
