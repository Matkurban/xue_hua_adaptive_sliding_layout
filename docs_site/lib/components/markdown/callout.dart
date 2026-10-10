import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/doc_page.dart';

/// Admonition box. Body is a slot, so callers can pass any content.
class Callout extends StatelessComponent {
  const Callout({required this.kind, required this.child, this.title, super.key});

  final CalloutKind kind;
  final String? title;
  final Component child;

  static String _icon(CalloutKind kind) => switch (kind) {
    CalloutKind.info => 'ℹ️',
    CalloutKind.tip => '💡',
    CalloutKind.warning => '⚠️',
    CalloutKind.danger => '⛔',
  };

  @override
  Component build(BuildContext context) {
    return aside(
      classes: 'callout callout--${kind.name}',
      attributes: {'role': 'note'},
      [
        div(classes: 'callout__title', [
          span(attributes: {'aria-hidden': 'true'}, [.text(_icon(kind))]),
          .text(title ?? context.l10n.calloutTitle(kind)),
        ]),
        div(classes: 'callout__body', [child]),
      ],
    );
  }
}
