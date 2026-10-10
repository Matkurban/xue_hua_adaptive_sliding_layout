import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../components/layout/site_shell.dart';
import '../models/doc_id.dart';
import '../pages/doc_detail_page.dart';
import '../pages/home_page.dart';
import '../pages/not_found_page.dart';
import 'app_paths.dart';

/// Routes are generated from [DocId], so every doc page is automatically
/// registered and — in static mode — pre-rendered to `/docs/<slug>/index.html`.
class AppRouter extends StatelessComponent {
  const AppRouter({super.key});

  @override
  Component build(BuildContext context) {
    return Router(
      redirect: (context, state) {
        final location = state.location;
        if (AppPaths.base == '' && location == AppPaths.docsRoot) {
          return AppPaths.doc(DocId.introduction);
        }
        return null;
      },
      errorBuilder: (context, state) => SiteShell(location: state.location, child: const NotFoundPage()),
      routes: [
        ShellRoute(
          builder: (context, state, child) => SiteShell(location: state.location, child: child),
          routes: [
            Route(path: AppPaths.home, builder: (context, state) => const HomePage()),
            for (final id in DocId.values)
              Route(
                path: AppPaths.doc(id),
                builder: (context, state) => DocDetailPage(id: id),
              ),
          ],
        ),
      ],
    );
  }
}
