import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../models/doc_id.dart';
import '../../routes/app_paths.dart';
import '../common/app_link.dart';

/// Renders the inline-markdown subset used in content strings:
/// `code`, **bold** and [label](href). `doc:<slug>` hrefs are resolved
/// through [DocId] so internal links stay type-checked at render time and
/// use client-side navigation.
class InlineMarkdown extends StatelessComponent {
  const InlineMarkdown(this.source, {super.key});

  final String source;

  static final _pattern = RegExp(r'`([^`]+)`|\*\*([^*]+)\*\*|\[([^\]]+)\]\(([^)]+)\)');
  static const _docScheme = 'doc:';

  @override
  Component build(BuildContext context) {
    final children = <Component>[];
    var last = 0;
    for (final m in _pattern.allMatches(source)) {
      if (m.start > last) children.add(.text(source.substring(last, m.start)));
      if (m[1] != null) {
        children.add(code(classes: 'inline-code', [.text(m[1]!)]));
      } else if (m[2] != null) {
        children.add(strong([.text(m[2]!)]));
      } else {
        children.add(_link(m[3]!, m[4]!));
      }
      last = m.end;
    }
    if (last < source.length) children.add(.text(source.substring(last)));
    return .fragment(children);
  }

  Component _link(String label, String href) {
    if (href.startsWith(_docScheme)) {
      final slug = href.substring(_docScheme.length);
      final id = DocId.values.where((d) => d.slug == slug).firstOrNull;
      assert(id != null, 'Unknown doc link: $href');
      if (id != null) return AppLink(to: AppPaths.doc(id), child: .text(label));
    }
    return a(href: href, target: Target.blank, attributes: {'rel': 'noopener'}, [.text(label)]);
  }
}
