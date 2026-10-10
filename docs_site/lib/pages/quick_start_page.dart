import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../l10n/l10n_provider.dart';
import '../models/doc_id.dart';
import 'doc_detail_page.dart';

/// Quick start = generic [DocDetailPage] + a "steps" intro slot
/// (composition, not inheritance).
///
/// It is deliberately a `const` [DocDetailPage] instance rather than a wrapper
/// component: every doc route then has the same component depth, so the
/// `Document.head` of the previous page is updated in place on client-side
/// navigation (a wrapper made jaspr keep the deeper, stale head entry).
const quickStartPage = DocDetailPage(id: DocId.quickStart, intro: QuickStartSteps());

class QuickStartSteps extends StatelessComponent {
  const QuickStartSteps({super.key});

  @override
  Component build(BuildContext context) {
    final l10n = context.l10n;
    return section(
      classes: 'steps',
      attributes: {'aria-label': l10n.quickStartStepsTitle},
      [
        h2(classes: 'steps__title', [.text(l10n.quickStartStepsTitle)]),
        ol(classes: 'steps__list', [
          for (final (i, step) in l10n.quickStartSteps.indexed)
            li(classes: 'steps__item', [
              span(classes: 'steps__num', [.text('${i + 1}')]),
              div([
                strong([.text(step.title)]),
                p([.text(step.body)]),
              ]),
            ]),
        ]),
      ],
    );
  }
}
