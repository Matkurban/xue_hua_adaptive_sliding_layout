import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

/// Chrome that changes shape at the compact breakpoint, as in the tutorial:
/// bottom bar below 600, navigation rail from 600.
AdaptiveRouter _router() {
  return AdaptiveRouter(
    initialLocation: '/products',
    routes: [
      AdaptiveShellRoute(
        builder: (context, shell, child) {
          if (shell.isCompact) {
            return AdaptiveShellChrome(
              bottomNavigationBar: (context) => const SizedBox(height: 56, child: Text('bottom-bar')),
              child: child,
            );
          }
          return Scaffold(
            body: Row(children: [const SizedBox(width: 80, child: Text('rail')), Expanded(child: child)]),
          );
        },
        branches: [
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: '/products',
                builder: (context, state) => Scaffold(
                  body: TextButton(
                    onPressed: () => AdaptiveRouter.of(context).pushNamed('/products/1'),
                    child: const Text('open-detail'),
                  ),
                ),
                routes: [
                  AdaptiveRoute(path: ':id', builder: (context, state) => const Scaffold(body: Text('detail-page'))),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shrinking across the compact breakpoint keeps the page stack', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(700, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-detail'));
    await tester.pumpAndSettle();
    expect(find.text('detail-page'), findsOneWidget);
    expect(router.matches.value.last?.matchedLocation, '/products/1');

    // medium (rail) -> compact (bottom bar)
    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpAndSettle();
    expect(router.matches.value.last?.matchedLocation, '/products/1');
    expect(find.text('detail-page'), findsOneWidget);

    // and back again
    tester.view.physicalSize = const Size(700, 800);
    await tester.pumpAndSettle();
    expect(router.matches.value.last?.matchedLocation, '/products/1');
    expect(find.text('detail-page'), findsOneWidget);
  });
}
