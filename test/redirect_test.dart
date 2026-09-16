import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

Widget _page(BuildContext context, AdaptiveRouteState state) {
  return Scaffold(body: Text('page-${state.matchedLocation}'));
}

AdaptiveRouter _router({
  AdaptiveRedirect? redirect,
  String initialLocation = '/',
}) {
  return AdaptiveRouter(
    initialLocation: initialLocation,
    redirect: redirect,
    errorBuilder: (context, state) => Text('error-${state.uri.path}'),
    routes: [
      AdaptiveRoute(path: '/', redirect: (_, _) => '/mail'),
      AdaptiveRoute(path: '/login', fullscreen: true, builder: _page),
      AdaptiveShellRoute(
        builder: (context, shell, child) => child,
        branches: [
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: '/mail',
                builder: _page,
                routes: [AdaptiveRoute(path: 'inbox', builder: _page)],
              ),
            ],
          ),
          AdaptiveBranch(
            routes: [AdaptiveRoute(path: '/settings', builder: _page)],
          ),
        ],
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('root redirect lands on /mail', (tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(router.location.value, '/mail');
    expect(find.text('page-/mail'), findsOneWidget);
  });

  testWidgets('top-level redirect guards /settings', (tester) async {
    var signedIn = false;
    final router = _router(
      initialLocation: '/settings',
      redirect: (context, state) {
        if (signedIn) return null;
        if (state.uri.path == '/settings') return '/login';
        return null;
      },
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(router.location.value, '/login');
    expect(find.text('page-/login'), findsOneWidget);

    signedIn = true;
    router.refresh();
    await tester.pumpAndSettle();
    expect(find.text('page-/login'), findsOneWidget);
  });

  testWidgets('redirect loop reports errorBuilder', (tester) async {
    final router = AdaptiveRouter(
      initialLocation: '/a',
      redirectLimit: 3,
      redirect: (context, state) => state.uri.path == '/a' ? '/b' : '/a',
      errorBuilder: (context, state) => Text('loop-${state.error}'),
      routes: [
        AdaptiveRoute(path: '/a', builder: _page),
        AdaptiveRoute(path: '/b', builder: _page),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.textContaining('loop-'), findsOneWidget);
  });
}
