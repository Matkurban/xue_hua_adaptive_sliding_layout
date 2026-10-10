import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

enum ContainerWidth { content, wide }

/// Centers its child with responsive horizontal padding and a max width.
class ResponsiveContainer extends StatelessComponent {
  const ResponsiveContainer({required this.child, this.width = ContainerWidth.wide, this.classes, super.key});

  final Component child;
  final ContainerWidth width;
  final String? classes;

  @override
  Component build(BuildContext context) =>
      div(classes: ['container', 'container--${width.name}', ?classes].join(' '), [child]);
}
