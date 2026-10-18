import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

/// The default breadcrumb strip uses an InkWell. A host shell that has no
/// Scaffold / Material above `child` must still work on expanded widths.
void main() {
  for (final width in [840.0, 1000.0, 1400.0]) {
    testWidgets(
      'shell without Scaffold or Material shows default breadcrumbs at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = AdaptiveRouter(
          initialLocation: '/products',
          routes: [
            AdaptiveShellRoute(
              // deliberately no Scaffold / Material
              builder: (context, shell, child) =>
                  Column(children: [Expanded(child: child)]),
              branches: [
                AdaptiveBranch(
                  routes: [
                    AdaptiveRoute(
                      path: '/products',
                      title: (state) => 'Products',
                      builder: (context, state) =>
                          const Scaffold(body: Text('list-page')),
                      routes: [
                        AdaptiveRoute(
                          path: ':id',
                          title: (state) => 'Detail',
                          builder: (context, state) =>
                              const Scaffold(body: Text('detail-page')),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        router.pushNamed('/products/1');
        await tester.pumpAndSettle();
        expect(find.text('detail-page'), findsOneWidget);
        expect(
          find.text('Products'),
          findsOneWidget,
          reason: 'breadcrumb strip is drawn',
        );
        expect(find.text('Detail'), findsOneWidget);
        expect(tester.takeException(), isNull);
        // the crumb is tappable (InkWell) and pops back to the list
        await tester.tap(find.text('Products'));
        await tester.pumpAndSettle();
        expect(router.location.value, '/products');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
