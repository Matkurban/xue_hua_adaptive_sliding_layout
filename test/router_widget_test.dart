import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

Widget _page(BuildContext context, AdaptiveRouteState state) {
  return Scaffold(
    appBar: AppBar(title: Text(state.matchedLocation)),
    body: Column(
      children: [
        Text('page-${state.matchedLocation}'),
        TextButton(
          onPressed: () {
            AdaptiveRouter.of(context).pushNamed('/mail/inbox');
          },
          child: const Text('open-inbox'),
        ),
        TextButton(
          onPressed: () {
            AdaptiveRouter.of(context).pushNamed('/photo/9');
          },
          child: const Text('open-photo'),
        ),
        TextButton(
          onPressed: () {
            AdaptiveRouter.of(context).pushNamed('/mail/compose');
          },
          child: const Text('open-compose'),
        ),
        TextButton(
          onPressed: () {
            AdaptiveRouter.of(context).pushNamed('/missing');
          },
          child: const Text('open-missing'),
        ),
      ],
    ),
  );
}

AdaptiveRouter _createRouter({
  bool escapePops = true,
  bool inboxHidesBar = true,
  AdaptiveOnExit? inboxOnExit,
  AdaptiveBreadcrumbsBuilder? breadcrumbsBuilder,
}) {
  return AdaptiveRouter(
    initialLocation: '/mail',
    errorBuilder: (context, state) =>
        Scaffold(body: Text('error-${state.uri.path}')),
    routes: [
      AdaptiveRoute(
        path: '/photo/:id',
        fullscreen: true,
        builder: (context, state) =>
            Scaffold(body: Text('photo-${state.pathParameters['id']}')),
      ),
      AdaptiveShellRoute(
        breakpoints: const LayoutBreakpoints(
          compactMaxWidth: 600,
          expandedMinWidth: 840,
        ),
        escapePops: escapePops,
        breadcrumbsBuilder: breadcrumbsBuilder,
        builder: (context, shell, child) {
          return Column(
            children: [
              Text('cols-${shell.visibleColumnCount}'),
              Text('branch-${shell.currentIndex}'),
              Expanded(child: child),
            ],
          );
        },
        branches: [
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: '/mail',
                builder: _page,
                routes: [
                  AdaptiveRoute(
                    path: 'inbox',
                    hidesBottomBarWhenPushed: inboxHidesBar,
                    onExit: inboxOnExit,
                    builder: _page,
                  ),
                  AdaptiveRoute(
                    path: 'compose',
                    fullscreenDialog: true,
                    builder: _page,
                  ),
                ],
              ),
            ],
          ),
          AdaptiveBranch(
            routes: [AdaptiveRoute(path: '/contacts', builder: _page)],
          ),
        ],
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setWidth(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('expanded width shows two columns', (tester) async {
    await setWidth(tester, 1200);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('cols-2'), findsOneWidget);
    expect(find.text('page-/mail'), findsOneWidget);
  });

  testWidgets('compact width shows one column', (tester) async {
    await setWidth(tester, 400);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('cols-1'), findsOneWidget);
  });

  testWidgets('compact push hides the shell chrome by default', (tester) async {
    await setWidth(tester, 400);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('branch-0'), findsOneWidget);
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail/inbox');
    expect(find.text('page-/mail/inbox'), findsOneWidget);
    expect(find.text('branch-0'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
    expect(find.text('branch-0'), findsOneWidget);
  });

  testWidgets('expanded width ignores hidesBottomBarWhenPushed', (
    tester,
  ) async {
    await setWidth(tester, 1200);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    expect(find.text('cols-2'), findsOneWidget);
    expect(find.text('page-/mail'), findsOneWidget);
    expect(find.text('page-/mail/inbox'), findsOneWidget);
  });

  testWidgets('hidesBottomBarWhenPushed false keeps the shell; '
      'fullscreenDialog covers it', (tester) async {
    await setWidth(tester, 400);
    final router = _createRouter(inboxHidesBar: false);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail/inbox');
    expect(find.text('branch-0'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
    await tester.tap(find.text('open-compose'));
    await tester.pumpAndSettle();
    expect(find.text('page-/mail/compose'), findsOneWidget);
    expect(find.text('branch-0'), findsNothing);
    expect(find.byType(CloseButton), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
    expect(find.text('branch-0'), findsOneWidget);
  });

  testWidgets('pushNamed opens inbox then AppBar back pops', (tester) async {
    await setWidth(tester, 400);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail/inbox');
    expect(find.text('page-/mail/inbox'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
  });

  testWidgets('fullscreen photo covers the shell', (tester) async {
    await setWidth(tester, 1200);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-photo'));
    await tester.pumpAndSettle();
    expect(find.text('photo-9'), findsOneWidget);
    expect(router.location.value, '/photo/9');
  });

  testWidgets('unknown route uses errorBuilder', (tester) async {
    await setWidth(tester, 400);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-missing'));
    await tester.pumpAndSettle();
    expect(find.text('error-/missing'), findsOneWidget);
  });

  testWidgets('setNewRoutePath restores a deep link', (tester) async {
    await setWidth(tester, 1200);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await router.routerDelegate.setNewRoutePath(
      router.registry.match(Uri.parse('/mail/inbox')),
    );
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail/inbox');
    expect(find.text('page-/mail/inbox'), findsOneWidget);
  });

  testWidgets('Escape pops the stack', (tester) async {
    await setWidth(tester, 400);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
  });

  testWidgets('escapePops false ignores Escape', (tester) async {
    await setWidth(tester, 400);
    final router = _createRouter(escapePops: false);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail/inbox');
  });

  testWidgets('maybePop honors onExit; pop skips it', (tester) async {
    await setWidth(tester, 400);
    final router = _createRouter(inboxOnExit: (_, _) async => false);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    expect(await router.maybePop(), isFalse);
    expect(router.location.value, '/mail/inbox');
    router.pop();
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
  });

  testWidgets('pushNamed future completes on pop', (tester) async {
    await setWidth(tester, 400);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    final future = router.pushNamed<String>('/mail/inbox');
    await tester.pumpAndSettle();
    router.pop('done');
    await tester.pumpAndSettle();
    expect(await future, 'done');
  });

  testWidgets('goBranch remembers the previous location', (tester) async {
    await setWidth(tester, 400);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    router.goBranch(1);
    await tester.pumpAndSettle();
    expect(router.location.value, '/contacts');
    router.goBranch(0);
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail/inbox');
  });

  testWidgets('breadcrumbsBuilder replaces the default strip', (tester) async {
    await setWidth(tester, 1200);
    final router = _createRouter(
      breadcrumbsBuilder: (context, panes, onSelect) {
        return const Text('custom-crumbs');
      },
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('custom-crumbs'), findsOneWidget);
    expect(find.byType(AdaptiveBreadcrumbs), findsNothing);
  });
}
