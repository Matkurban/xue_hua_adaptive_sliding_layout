import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../models/doc_id.dart';
import '../../models/doc_page.dart';
import '../../routes/app_paths.dart';
import '../code/code_block.dart';
import 'callout.dart';
import 'inline_markdown.dart';

/// Renders a list of typed [DocBlock]s. The exhaustive `switch` over the
/// sealed hierarchy is the "markdown renderer" of this site.
class DocContent extends StatelessComponent {
  const DocContent(this.blocks, {required this.pageId, super.key});

  final List<DocBlock> blocks;

  /// Used to build anchor hrefs that resolve correctly against `<base href>`.
  final DocId pageId;

  @override
  Component build(BuildContext context) => .fragment([for (final b in blocks) _block(b)]);

  Component _block(DocBlock block) => switch (block) {
    DocHeading(:final anchor, :final text, :final level) => _heading(level, anchor, text),
    DocParagraph(:final text) => p([InlineMarkdown(text)]),
    DocCode(:final language, :final code, :final fileName) => CodeBlock(
      code: code,
      language: language,
      fileName: fileName,
    ),
    DocCallout(:final kind, :final text, :final title) => Callout(
      kind: kind,
      title: title,
      child: InlineMarkdown(text),
    ),
    DocList(:final items, :final ordered) => () {
      final children = [
        for (final i in items) li([InlineMarkdown(i)]),
      ];
      return ordered ? ol(children) : ul(children);
    }(),
    DocTable(:final header, :final rows) => div(classes: 'table-wrap', [
      table([
        thead([
          tr([
            for (final h in header) th([InlineMarkdown(h)]),
          ]),
        ]),
        tbody([
          for (final r in rows)
            tr([
              for (final c in r) td([InlineMarkdown(c)]),
            ]),
        ]),
      ]),
    ]),
  };

  Component _heading(int level, String anchor, String text) {
    final children = <Component>[
      .text(text),
      a(
        href: AppPaths.anchor(pageId, anchor),
        classes: 'heading-anchor',
        attributes: {'aria-hidden': 'true'},
        [const .text('#')],
      ),
    ];
    return level <= 2 ? h2(id: anchor, children) : h3(id: anchor, children);
  }
}
