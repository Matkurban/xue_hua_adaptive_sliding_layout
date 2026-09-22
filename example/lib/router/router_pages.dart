import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/model/domains/product.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/auth/login_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/auth/register_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/auth/splash_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/contacts/contact_detail_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/contacts/contact_edit_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/contacts/contacts_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/home/home_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/home/image_preview_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/home/product_detail_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/mine/about_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/mine/account_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/mine/mine_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/mine/theme_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/shopping_cart/shopping_cart_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/empty_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/not_found_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_names.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/app_setting_services.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/contact_services.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/shell/app_shell.dart';

sealed class RouterPages {
  static AdaptiveRouter router = AdaptiveRouter(
    initialLocation: RouterNames.splash,
    redirect: (context, state) {
      final path = state.uri.path;
      if (path.startsWith(RouterNames.account) &&
          !AppSettingServices.instance.signedIn.value) {
        return '${RouterNames.login}?from=${Uri.encodeComponent(state.uri.toString())}';
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
                title: (_) => '首页',
                builder: (context, state) => const HomePage(),
                routes: [
                  AdaptiveRoute(
                    path: ':id',
                    name: RouterNames.product,
                    title: (state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) return '商品';
                      return findMockProduct(id)?.name ?? '商品';
                    },
                    builder: (context, state) => const ProductDetailPage(),
                    routes: [
                      AdaptiveRoute(
                        path: 'preview',
                        name: RouterNames.preview,
                        title: (_) => '图片预览',
                        fullscreen: true,
                        opaque: false,
                        barrierColor: Colors.black,
                        barrierDismissible: true,
                        transitionDuration: const Duration(milliseconds: 200),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                        builder: (context, state) => const ImagePreviewPage(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: RouterNames.shopping,
                name: 'Shopping',
                title: (_) => '购物车',
                builder: (context, state) => const ShoppingCartPage(),
              ),
            ],
          ),
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: RouterNames.contacts,
                title: (_) => '联系人',
                builder: (context, state) => const ContactsPage(),
                routes: [
                  AdaptiveRoute(
                    path: ':id',
                    name: RouterNames.contact,
                    title: (state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) return '联系人';
                      return ContactServices.instance.find(id)?.name ?? '联系人';
                    },
                    builder: (context, state) => const ContactDetailPage(),
                    routes: [
                      AdaptiveRoute(
                        path: 'edit',
                        name: RouterNames.contactEdit,
                        title: (_) => '编辑备注',
                        onExit: (context, state) async {
                          if (!ContactServices.instance.remarkDirty.value) {
                            return true;
                          }
                          final leave = await showDialog<bool>(
                            context: context,
                            useRootNavigator:
                                AdaptivePaneScope.maybeOf(context) != null,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('放弃修改？'),
                                content: const Text('备注还没有保存。'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: const Text('继续编辑'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: const Text('放弃'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (leave == true) {
                            ContactServices.instance.remarkDirty.value = false;
                            return true;
                          }
                          return false;
                        },
                        builder: (context, state) => const ContactEditPage(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: RouterNames.mine,
                title: (_) => '我的',
                builder: (context, state) => const MinePage(),
                routes: [
                  AdaptiveRoute(
                    path: 'theme',
                    title: (_) => '主题',
                    hidesBottomBarWhenPushed: false,
                    builder: (context, state) => const ThemePage(),
                  ),
                  AdaptiveRoute(
                    path: 'account',
                    title: (_) => '账号',
                    builder: (context, state) => const AccountPage(),
                  ),
                  AdaptiveRoute(
                    path: 'about',
                    title: (_) => '关于',
                    fullscreenDialog: true,
                    builder: (context, state) => const AboutPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
