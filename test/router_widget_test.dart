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
            AdaptiveRouter.of(context).pushNamed('/missing');
          },
          child: const Text('open-missing'),
        ),
      ],
    ),
  );
}

AdaptiveRouter _createRouter() {
  return AdaptiveRouter(
    initialLocation: '/mail',
    errorBuilder: (context, state) => Scaffold(
      body: Text('error-${state.uri.path}'),
    ),
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
                  AdaptiveRoute(path: 'inbox', builder: _page),
                ],
              ),
            ],
          ),
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(path: '/contacts', builder: _page),
            ],
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
}
