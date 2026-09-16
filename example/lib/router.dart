import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/data/auth.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/features/contacts/contact_pages.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/features/mail/mail_pages.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/features/playground/playground_page.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/features/settings/settings_pages.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/misc_pages.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/shell/app_shell.dart';

/// 示例应用的路由器。宿主直接持有实例，无需 DI。
final AdaptiveRouter appRouter = createAppRouter();

/// 完整路由表，可当作接入模板照抄。
AdaptiveRouter createAppRouter() {
  return AdaptiveRouter(
    initialLocation: '/mail',
    redirect: (context, state) {
      final path = state.uri.path;
      if (path.startsWith('/settings/account') && !signedIn.value) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      return null;
    },
    errorBuilder: (context, state) => NotFoundPage(uri: state.uri),
    routes: [
      AdaptiveRoute(path: '/', redirect: (_, _) => '/mail'),
      AdaptiveRoute(
        path: '/login',
        fullscreen: true,
        builder: (context, state) => const LoginPage(),
      ),
      AdaptiveRoute(
        path: '/photo/:id',
        name: 'photo',
        fullscreen: true,
        transitionsBuilder: (context, animation, secondary, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        builder: (context, state) =>
            PhotoPage(id: state.pathParameters['id'] ?? ''),
      ),
      AdaptiveShellRoute(
        showBreadcrumbs: true,
        resizable: true,
        initialLeftPaneFraction: 0.4,
        builder: (context, shell, child) =>
            AppShell(shell: shell, child: child),
        branches: [
          AdaptiveBranch(
            placeholder: (context) => const EmptyDetail(),
            routes: [
              AdaptiveRoute(
                path: '/mail',
                title: (_) => 'Mail',
                builder: (context, state) => const MailFoldersPage(),
                routes: [
                  AdaptiveRoute(
                    path: ':folder',
                    builder: (context, state) => MailFolderPage(
                      folder: state.pathParameters['folder'] ?? 'inbox',
                    ),
                    routes: [
                      AdaptiveRoute(
                        path: ':threadId',
                        name: 'thread',
                        title: (s) =>
                            'Thread ${s.pathParameters['threadId']}',
                        builder: (context, state) => MailThreadPage(
                          folder: state.pathParameters['folder'] ?? 'inbox',
                          threadId: state.pathParameters['threadId'] ?? '',
                        ),
                        routes: [
                          AdaptiveRoute(
                            path: 'reply',
                            name: 'reply',
                            onExit: _confirmIf(mailReplyDirty),
                            builder: (context, state) => MailReplyPage(
                              folder: state.pathParameters['folder'] ?? '',
                              threadId: state.pathParameters['threadId'] ?? '',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          AdaptiveBranch(
            placeholder: (context) => const EmptyDetail(),
            routes: [
              AdaptiveRoute(
                path: '/contacts',
                name: 'contacts',
                title: (_) => 'Contacts',
                builder: (context, state) => ContactsPage(
                  query: state.queryParameters['q'] ?? '',
                ),
                routes: [
                  AdaptiveRoute(
                    path: ':id',
                    name: 'contact',
                    builder: (context, state) =>
                        ContactDetailPage(id: state.pathParameters['id'] ?? ''),
                    routes: [
                      AdaptiveRoute(
                        path: 'edit',
                        onExit: _confirmIf(contactEditDirty),
                        builder: (context, state) => ContactEditPage(
                          id: state.pathParameters['id'] ?? '',
                        ),
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
                path: '/settings',
                title: (_) => 'Settings',
                builder: (context, state) => const SettingsHomePage(),
                routes: [
                  AdaptiveRoute(
                    path: 'account',
                    builder: (context, state) => const SettingsAccountPage(),
                  ),
                  AdaptiveRoute(
                    path: 'appearance',
                    builder: (context, state) =>
                        const SettingsAppearancePage(),
                  ),
                  AdaptiveRoute(
                    path: 'about',
                    builder: (context, state) => const SettingsAboutPage(),
                  ),
                ],
              ),
            ],
          ),
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: '/playground',
                title: (_) => 'Playground',
                builder: (context, state) => const PlaygroundPage(),
                routes: [
                  AdaptiveRoute(
                    path: 'color',
                    builder: (context, state) => const ColorPickerPage(),
                  ),
                  AdaptiveRoute(
                    path: 'replaced',
                    builder: (context, state) =>
                        const PlaygroundReplacedPage(),
                  ),
                  AdaptiveRoute(
                    path: 'fade',
                    fullscreen: true,
                    transitionsBuilder: (context, animation, secondary, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    builder: (context, state) => const PlaygroundFadePage(),
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

AdaptiveOnExit _confirmIf(Signal<bool> dirty) {
  return (context, state) async {
    if (!dirty.value) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
    if (ok == true) dirty.value = false;
    return ok ?? false;
  };
}
