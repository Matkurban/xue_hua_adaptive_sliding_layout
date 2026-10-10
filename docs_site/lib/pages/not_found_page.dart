import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/common/seo_head.dart';
import '../components/layout/responsive_container.dart';
import '../l10n/l10n_provider.dart';
import '../routes/app_paths.dart';
import '../components/common/app_link.dart';

class NotFoundPage extends StatelessComponent {
  const NotFoundPage({super.key});

  @override
  Component build(BuildContext context) {
    final l10n = context.l10n;
    return ResponsiveContainer(
      width: ContainerWidth.content,
      classes: 'not-found',
      child: .fragment([
        SeoHead(title: l10n.notFoundTitle, description: l10n.notFoundBody, path: AppPaths.home),
        const h1([.text('404')]),
        p([.text(l10n.notFoundBody)]),
        AppLink(to: AppPaths.home, classes: 'btn btn--primary', child: .text(l10n.navHome)),
      ]),
    );
  }
}
