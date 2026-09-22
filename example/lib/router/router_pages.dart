import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/auth/login_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/auth/register_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/auth/splash_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/contacts/contacts_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/home/home_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/mine/mine_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/shopping_cart/shopping_cart_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/empty_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/not_found_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_names.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/app_setting_services.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/shell/app_shell.dart';

sealed class RouterPages {
  static AdaptiveRouter router = AdaptiveRouter(
    initialLocation: RouterNames.splash,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path.startsWith('/settings/account') &&
          !AppSettingServices.instance.signedIn.value) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      return null;
    },
    errorBuilder: (context, state) => NotFoundPage(uri: state.uri),
    routes: [
      AdaptiveRoute(path: '/', redirect: (_, _) => RouterNames.splash),
      AdaptiveRoute(
        path: RouterNames.splash,
        fullscreen: true,
        builder: (context, state) => const SplashPage(),
      ),
      AdaptiveRoute(
        path: RouterNames.login,
        fullscreen: true,
        builder: (context, state) => const LoginPage(),
      ),
      AdaptiveRoute(
        path: RouterNames.register,
        fullscreen: true,
        builder: (context, state) => const RegisterPage(),
      ),

      AdaptiveShellRoute(
        showBreadcrumbs: true,
        resizable: true,
        initialLeftPaneFraction: 0.4,
        placeholder: (context) => const EmptyPage(),
        slideDuration: const Duration(milliseconds: 280),
        breadcrumbsBuilder: (context, panes, onSelect) {
          return AdaptiveBreadcrumbs(
            panes: panes,
            onSelect: onSelect,
            height: 32,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          );
        },
        paneBuilder: (context, index, child) {
          return KeyedSubtree(key: const Key('pane-flat'), child: child);
        },
        builder: (context, shell, child) =>
            AppShell(shell: shell, child: child),
        branches: [
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: RouterNames.home,
                title: (_) => 'Home',
                builder: (context, state) => const HomePage(),
                routes: [],
              ),
            ],
          ),
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: RouterNames.shopping,
                name: 'Shopping',
                title: (_) => 'Shopping Cart',
                builder: (context, state) => ShoppingCartPage(),
                routes: [],
              ),
            ],
          ),
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: RouterNames.contacts,
                title: (_) => 'Contacts',
                builder: (context, state) => const ContactsPage(),
                routes: [],
              ),
            ],
          ),
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: RouterNames.mine,
                title: (_) => 'Mine',
                builder: (context, state) => const MinePage(),
                routes: [],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
