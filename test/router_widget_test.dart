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
  AdaptiveOnExit? mailOnExit,
  bool inboxPopScope = false,
  bool shellPopScope = false,
  List<bool>? popInvoked,
  AdaptiveBreadcrumbsBuilder? breadcrumbsBuilder,
}) {
  Widget maybePopScope(Widget child) {
    if (!inboxPopScope && !shellPopScope) return child;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        popInvoked?.add(didPop);
      },
      child: child,
    );
  }

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
          Widget built = Column(
            children: [
              Text('cols-${shell.visibleColumnCount}'),
              Text('branch-${shell.currentIndex}'),
              Expanded(child: child),
            ],
          );
          if (shellPopScope) built = maybePopScope(built);
          return built;
        },
        branches: [
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: '/mail',
                onExit: mailOnExit,
                builder: _page,
                routes: [
                  AdaptiveRoute(
                    path: 'inbox',
                    hidesBottomBarWhenPushed: inboxHidesBar,
                    onExit: inboxOnExit,
                    builder: (context, state) {
                      final page = _page(context, state);
                      return inboxPopScope ? maybePopScope(page) : page;
                    },
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

/// 在显示 [on] 文本的页上打开对话框。[root] 为 true 时挂到根 Navigator，
/// 否则挂到该页最近的 Navigator（双栏下即栏内 Navigator）。
Future<void> _openDialog(
  WidgetTester tester, {
  String on = 'page-/mail/inbox',
  required bool root,
  Key key = const Key('test-dialog'),
}) async {
  showDialog<void>(
    context: tester.element(find.text(on)),
    useRootNavigator: root,
    builder: (context) => AlertDialog(key: key, title: const Text('Dialog')),
  );
  await tester.pumpAndSettle();
  expect(find.byKey(key), findsOneWidget);
}

/// 双栏：左栏 `/mail` 开栏内对话框后再推入右栏 `/mail/inbox`——用户报告的场景。
Future<AdaptiveRouter> _pumpLeftDialogThenInbox(
  WidgetTester tester, {
  bool root = false,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = _createRouter();
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  await _openDialog(tester, on: 'page-/mail', root: root);
  router.pushNamed('/mail/inbox');
  await tester.pumpAndSettle();
  expect(find.text('page-/mail'), findsOneWidget);
  expect(find.text('page-/mail/inbox'), findsOneWidget);
  expect(find.byKey(const Key('test-dialog')), findsOneWidget);
  return router;
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

  testWidgets('goBranch restores arguments on a previously visited branch', (
    tester,
  ) async {
    await setWidth(tester, 400);
    final router = AdaptiveRouter(
      initialLocation: '/mail',
      routes: [
        AdaptiveShellRoute(
          breakpoints: const LayoutBreakpoints(
            compactMaxWidth: 600,
            expandedMinWidth: 840,
          ),
          builder: (context, shell, child) {
            return Column(
              children: [
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
                  builder: (context, state) {
                    return Scaffold(
                      body: TextButton(
                        onPressed: () {
                          AdaptiveRouter.of(context).pushNamed(
                            '/mail/detail',
                            arguments: 'secret-payload',
                          );
                        },
                        child: const Text('open-detail'),
                      ),
                    );
                  },
                  routes: [
                    AdaptiveRoute(
                      path: 'detail',
                      builder: (context, state) {
                        return Scaffold(body: Text(state.arguments! as String));
                      },
                    ),
                  ],
                ),
              ],
            ),
            AdaptiveBranch(
              routes: [
                AdaptiveRoute(
                  path: '/contacts',
                  builder: (context, state) =>
                      const Scaffold(body: Text('page-/contacts')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-detail'));
    await tester.pumpAndSettle();
    expect(find.text('secret-payload'), findsOneWidget);
    router.goBranch(1);
    await tester.pumpAndSettle();
    router.goBranch(0);
    await tester.pumpAndSettle();
    expect(find.text('secret-payload'), findsOneWidget);
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

  testWidgets('PopScope blocks AppBar back in compact', (tester) async {
    await setWidth(tester, 400);
    final invoked = <bool>[];
    final router = _createRouter(inboxPopScope: true, popInvoked: invoked);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail/inbox');
    expect(invoked, [false]);
  });

  testWidgets('PopScope blocks system back in compact', (tester) async {
    await setWidth(tester, 400);
    final invoked = <bool>[];
    final router = _createRouter(inboxPopScope: true, popInvoked: invoked);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail/inbox');
    expect(invoked, [false]);
  });

  testWidgets('PopScope blocks Escape and maybePop; pop still pops', (
    tester,
  ) async {
    await setWidth(tester, 400);
    final invoked = <bool>[];
    final router = _createRouter(inboxPopScope: true, popInvoked: invoked);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail/inbox');
    expect(await router.maybePop(), isFalse);
    expect(router.location.value, '/mail/inbox');
    expect(invoked, [false, false]);
    router.pop();
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
  });

  testWidgets('PopScope blocks system back and Escape in expanded', (
    tester,
  ) async {
    await setWidth(tester, 1200);
    final invoked = <bool>[];
    final router = _createRouter(inboxPopScope: true, popInvoked: invoked);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail/inbox');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail/inbox');
    expect(invoked, [false, false]);
  });

  testWidgets('PopScope veto is not overridden by onExit true', (tester) async {
    await setWidth(tester, 400);
    final invoked = <bool>[];
    final router = _createRouter(
      inboxPopScope: true,
      inboxOnExit: (_, _) async => true,
      popInvoked: invoked,
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail/inbox');
    expect(invoked, [false]);
  });

  testWidgets('onExit false blocks back; system back does not exit the app', (
    tester,
  ) async {
    await setWidth(tester, 400);
    final router = _createRouter(inboxOnExit: (_, _) async => false);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail/inbox');
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail/inbox');
  });

  for (final width in [400.0, 1200.0]) {
    testWidgets(
      'shell PopScope blocks system back at root (${width.toInt()})',
      (tester) async {
        await setWidth(tester, width);
        final invoked = <bool>[];
        final router = _createRouter(shellPopScope: true, popInvoked: invoked);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();
        expect(router.location.value, '/mail');
        expect(invoked, [false]);
        invoked.clear();
        expect(await router.maybePop(), isFalse);
        expect(invoked, isEmpty);
      },
    );
  }

  testWidgets('shell PopScope keeps frameworkHandlesBack after first landing', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final handlesBack = <bool>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          handlesBack.add(call.arguments as bool);
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    await setWidth(tester, 400);
    final router = _createRouter(shellPopScope: true);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
    expect(handlesBack, isNotEmpty);
    expect(handlesBack.last, isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('root onExit false blocks app exit', (tester) async {
    await setWidth(tester, 400);
    final router = _createRouter(mailOnExit: (_, _) async => false);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
  });

  testWidgets('pop closes a dialog and leaves the page stack', (tester) async {
    await setWidth(tester, 400);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();

    await _openDialog(tester, root: false);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('test-dialog')), findsNothing);
    expect(router.location.value, '/mail/inbox');

    await _openDialog(tester, root: true);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('test-dialog')), findsNothing);
    expect(router.location.value, '/mail/inbox');

    router.pop();
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
  });

  testWidgets('pop closes pane and root dialogs on expanded width', (
    tester,
  ) async {
    await setWidth(tester, 1200);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    expect(find.text('page-/mail'), findsOneWidget);
    expect(find.text('page-/mail/inbox'), findsOneWidget);

    await _openDialog(tester, root: false);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('test-dialog')), findsNothing);
    expect(router.location.value, '/mail/inbox');
    expect(find.text('page-/mail/inbox'), findsOneWidget);

    await _openDialog(tester, root: true);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('test-dialog')), findsNothing);
    expect(router.location.value, '/mail/inbox');
    expect(find.text('page-/mail'), findsOneWidget);
  });

  testWidgets('maybePop closes a dialog without asking onExit', (tester) async {
    await setWidth(tester, 400);
    var exits = 0;
    final router = _createRouter(
      inboxOnExit: (_, _) async {
        exits++;
        return false;
      },
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();

    await _openDialog(tester, root: false);
    expect(await router.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('test-dialog')), findsNothing);
    expect(exits, 0);
    expect(router.location.value, '/mail/inbox');

    await _openDialog(tester, root: true);
    expect(await router.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('test-dialog')), findsNothing);
    expect(exits, 0);
    expect(router.location.value, '/mail/inbox');
  });

  testWidgets(
    'maybePopFrom / popFrom inside a left-pane dialog close only it',
    (tester) async {
      final router = await _pumpLeftDialogThenInbox(tester);
      var dialog = tester.element(find.byKey(const Key('test-dialog')));
      expect(await router.maybePopFrom(dialog), isTrue);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('test-dialog')), findsNothing);
      expect(router.location.value, '/mail/inbox');
      expect(find.text('page-/mail/inbox'), findsOneWidget);

      await _openDialog(tester, on: 'page-/mail', root: false);
      dialog = tester.element(find.byKey(const Key('test-dialog')));
      router.popFrom(dialog);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('test-dialog')), findsNothing);
      expect(router.location.value, '/mail/inbox');
    },
  );

  for (final root in [false, true]) {
    testWidgets(
      'maybePopFrom on a covered page closes its dialog (root: $root)',
      (tester) async {
        final router = await _pumpLeftDialogThenInbox(tester, root: root);
        final page = tester.element(find.text('page-/mail'));
        expect(await router.maybePopFrom(page), isTrue);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('test-dialog')), findsNothing);
        expect(router.location.value, '/mail/inbox');
      },
    );
  }

  testWidgets('maybePopFrom on the top page pops it and keeps the other '
      'pane dialog', (tester) async {
    final router = await _pumpLeftDialogThenInbox(tester);
    final inbox = tester.element(find.text('page-/mail/inbox'));
    expect(await router.maybePopFrom(inbox), isTrue);
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
    expect(find.byKey(const Key('test-dialog')), findsOneWidget);
  });

  testWidgets('one dialog per pane: each maybePopFrom closes its own', (
    tester,
  ) async {
    await setWidth(tester, 1200);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    const left = Key('left-dialog');
    const right = Key('right-dialog');
    await _openDialog(tester, on: 'page-/mail', root: false, key: left);
    await _openDialog(tester, on: 'page-/mail/inbox', root: false, key: right);

    expect(
      await router.maybePopFrom(tester.element(find.byKey(right))),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(right), findsNothing);
    expect(find.byKey(left), findsOneWidget);

    expect(await router.maybePopFrom(tester.element(find.byKey(left))), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(left), findsNothing);
    expect(router.location.value, '/mail/inbox');
  });

  testWidgets('popFrom hands the result to showDialog', (tester) async {
    await setWidth(tester, 1200);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    final result = showDialog<String>(
      context: tester.element(find.text('page-/mail')),
      useRootNavigator: false,
      builder: (context) => const AlertDialog(key: Key('test-dialog')),
    );
    await tester.pumpAndSettle();
    router.popFrom(tester.element(find.byKey(const Key('test-dialog'))), 'ok');
    await tester.pumpAndSettle();
    expect(await result, 'ok');
    expect(router.location.value, '/mail');
  });

  testWidgets('maybePopFrom on the top page honors onExit; popFrom skips it', (
    tester,
  ) async {
    await setWidth(tester, 400);
    var exits = 0;
    final router = _createRouter(
      inboxOnExit: (_, _) async {
        exits++;
        return false;
      },
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    final inbox = tester.element(find.text('page-/mail/inbox'));
    expect(await router.maybePopFrom(inbox), isFalse);
    expect(exits, 1);
    expect(router.location.value, '/mail/inbox');
    router.popFrom(inbox);
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
  });

  testWidgets('maybePopFrom outside pages falls back to maybePop', (
    tester,
  ) async {
    await setWidth(tester, 1200);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    expect(
      await router.maybePopFrom(tester.element(find.text('cols-2'))),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
  });

  testWidgets('maybePop only handles the top pane; the left-pane dialog '
      'stays', (tester) async {
    final router = await _pumpLeftDialogThenInbox(tester);
    expect(await router.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
    expect(find.byKey(const Key('test-dialog')), findsOneWidget);

    expect(await router.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('test-dialog')), findsNothing);
    expect(router.location.value, '/mail');
  });

  testWidgets('maybePop closes a root dialog before a pane dialog', (
    tester,
  ) async {
    await setWidth(tester, 1200);
    final router = _createRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    const pane = Key('pane-dialog');
    const root = Key('root-dialog');
    await _openDialog(tester, root: false, key: pane);
    await _openDialog(tester, root: true, key: root);

    expect(await router.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(root), findsNothing);
    expect(find.byKey(pane), findsOneWidget);

    expect(await router.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(pane), findsNothing);
    expect(router.location.value, '/mail/inbox');
  });

  testWidgets('system back in expanded leaves the onExit dialog open', (
    tester,
  ) async {
    await setWidth(tester, 1200);
    final router = _createRouter(
      inboxOnExit: (context, _) async {
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => const AlertDialog(key: Key('exit-dialog')),
        );
        return leave ?? false;
      },
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-inbox'));
    await tester.pumpAndSettle();
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exit-dialog')), findsOneWidget);
    expect(router.location.value, '/mail/inbox');
  });

  testWidgets('root onExit true lets the app exit', (tester) async {
    await setWidth(tester, 400);
    final router = _createRouter(mailOnExit: (_, _) async => true);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(await tester.binding.handlePopRoute(), isFalse);
    expect(router.location.value, '/mail');
  });
}
