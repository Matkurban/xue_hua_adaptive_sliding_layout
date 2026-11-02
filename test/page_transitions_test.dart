import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setWidth(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('AdaptivePageTransitionType enum & builders', () {
    test('provides 18 transition types (>= 10 required)', () {
      expect(
        AdaptivePageTransitionType.values.length,
        greaterThanOrEqualTo(18),
      );
      expect(
        AdaptivePageTransitionType.platform.builder(),
        isNull,
        reason: 'platform uses default AdaptiveMaterialRoute',
      );
      expect(AdaptivePageTransitionType.none.defaultDuration, Duration.zero);
      expect(
        AdaptivePageTransitionType.flipHorizontal.defaultDuration,
        const Duration(milliseconds: 400),
      );
      expect(
        AdaptivePageTransitionType.flipVertical.defaultDuration,
        const Duration(milliseconds: 400),
      );
      expect(
        AdaptivePageTransitionType.fade.defaultDuration,
        const Duration(milliseconds: 300),
      );
      for (final type in AdaptivePageTransitionType.values) {
        if (type == AdaptivePageTransitionType.platform) continue;
        expect(
          type.builder(),
          isNotNull,
          reason: '$type must provide a non-null transitionsBuilder',
        );
      }
    });

    for (final type in AdaptivePageTransitionType.values) {
      testWidgets(
        'push and pop route with transitionType: ${type.name} in compact & medium',
        (tester) async {
          await setWidth(tester, 400);
          final router = AdaptiveRouter(
            initialLocation: '/home',
            routes: [
              AdaptiveShellRoute(
                builder: (context, shell, child) => Scaffold(body: child),
                branches: [
                  AdaptiveBranch(
                    routes: [
                      AdaptiveRoute(
                        path: '/home',
                        builder: (context, state) => Scaffold(
                          appBar: AppBar(title: const Text('Home')),
                          body: const Text('page-home'),
                        ),
                        routes: [
                          AdaptiveRoute(
                            path: 'detail',
                            transitionType: type,
                            builder: (context, state) => Scaffold(
                              appBar: AppBar(title: const Text('Detail')),
                              body: Text('page-detail-${type.name}'),
                            ),
                            routes: [
                              AdaptiveRoute(
                                path: 'sub',
                                transitionType: type,
                                builder: (context, state) => Scaffold(
                                  appBar: AppBar(title: const Text('Sub')),
                                  body: Text('page-sub-${type.name}'),
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
            ],
          );

          await tester.pumpWidget(MaterialApp.router(routerConfig: router));
          await tester.pumpAndSettle();
          expect(find.text('page-home'), findsOneWidget);

          // Push detail page and pump mid-transition frames
          final pushDetail = router.pushNamed<String>('/home/detail');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 80));
          await tester.pump(const Duration(milliseconds: 120));
          await tester.pumpAndSettle();
          expect(find.text('page-detail-${type.name}'), findsOneWidget);
          // Underlying page should be marked offstage after opaque transition completes
          expect(find.text('page-home'), findsNothing);
          expect(find.text('page-home', skipOffstage: false), findsOneWidget);

          // Push 3rd-level sub page (exercises secondaryAnimation on detail)
          router.pushNamed<void>('/home/detail/sub');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();
          expect(find.text('page-sub-${type.name}'), findsOneWidget);
          expect(find.text('page-detail-${type.name}'), findsNothing);
          expect(
            find.text('page-detail-${type.name}', skipOffstage: false),
            findsOneWidget,
          );

          // Pop back to detail
          router.pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();
          expect(find.text('page-detail-${type.name}'), findsOneWidget);

          // Pop back to home with result
          router.pop('ok-${type.name}');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();
          expect(await pushDetail, 'ok-${type.name}');
          expect(find.text('page-home'), findsOneWidget);

          router.dispose();
        },
      );
    }
  });

  group('AdaptivePageTransitions configurable factory builders', () {
    testWidgets(
      'all parameterized AdaptivePageTransitions builders animate cleanly',
      (tester) async {
        await setWidth(tester, 400);
        final builders = <String, AdaptiveTransitionsBuilder>{
          'none': AdaptivePageTransitions.none,
          'fade': AdaptivePageTransitions.fade(curve: Curves.easeIn),
          'fadeThrough': AdaptivePageTransitions.fadeThrough(initialScale: 0.9),
          'slideRightToLeft-noParallax':
              AdaptivePageTransitions.slideRightToLeft(parallax: false),
          'slideLeftToRight-noParallax':
              AdaptivePageTransitions.slideLeftToRight(parallax: false),
          'slideBottomToTop': AdaptivePageTransitions.slideBottomToTop(),
          'slideTopToBottom': AdaptivePageTransitions.slideTopToBottom(),
          'cupertino-linear': AdaptivePageTransitions.cupertino(
            linearTransition: true,
          ),
          'scale-topLeft': AdaptivePageTransitions.scale(
            alignment: Alignment.topLeft,
            beginScale: 0.2,
          ),
          'fadeAndScale': AdaptivePageTransitions.fadeAndScale(
            alignment: Alignment.bottomCenter,
            beginScale: 0.75,
          ),
          'sharedAxisHorizontal': AdaptivePageTransitions.sharedAxisHorizontal(
            offset: 48,
          ),
          'sharedAxisVertical': AdaptivePageTransitions.sharedAxisVertical(
            offset: 48,
          ),
          'sharedAxisScale': AdaptivePageTransitions.sharedAxisScale(
            beginScale: 0.75,
            exitScale: 1.15,
          ),
          'rotation': AdaptivePageTransitions.rotation(
            beginTurns: 0.5,
            beginScale: 0.5,
          ),
          'size-horizontal': AdaptivePageTransitions.size(
            axis: Axis.horizontal,
            alignment: Alignment.centerLeft,
          ),
          'flipHorizontal': AdaptivePageTransitions.flipHorizontal(
            perspective: 0.002,
          ),
          'flipVertical': AdaptivePageTransitions.flipVertical(
            perspective: 0.002,
          ),
        };

        final router = AdaptiveRouter(
          initialLocation: '/root',
          routes: [
            AdaptiveRoute(
              path: '/root',
              builder: (context, state) => const Scaffold(body: Text('root')),
              routes: [
                for (final entry in builders.entries)
                  AdaptiveRoute(
                    path: entry.key,
                    transitionsBuilder: entry.value,
                    builder: (context, state) =>
                        Scaffold(body: Text('page-${entry.key}')),
                  ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        for (final name in builders.keys) {
          router.pushNamed('/root/$name');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 120));
          await tester.pumpAndSettle();
          expect(find.text('page-$name'), findsOneWidget);

          router.pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 120));
          await tester.pumpAndSettle();
          expect(find.text('root'), findsOneWidget);
        }

        router.dispose();
      },
    );
  });

  group('Transition configuration hierarchy (route > shell > router)', () {
    testWidgets(
      'router defaultTransitionType applies unless overridden by shell or route',
      (tester) async {
        await setWidth(tester, 400);
        final usedBuilders = <String>[];

        final router = AdaptiveRouter(
          initialLocation: '/a',
          defaultTransitionsBuilder:
              (context, animation, secondaryAnimation, child) {
                usedBuilders.add('router-default');
                return AdaptivePageTransitions.fade()(
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                );
              },
          routes: [
            AdaptiveRoute(
              path: '/overlay',
              fullscreen: true,
              builder: (context, state) =>
                  const Scaffold(body: Text('overlay')),
            ),
            AdaptiveShellRoute(
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    usedBuilders.add('shell-default');
                    return AdaptivePageTransitions.slideBottomToTop()(
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    );
                  },
              builder: (context, shell, child) => Scaffold(body: child),
              branches: [
                AdaptiveBranch(
                  routes: [
                    AdaptiveRoute(
                      path: '/a',
                      builder: (context, state) =>
                          const Scaffold(body: Text('root-a')),
                      routes: [
                        AdaptiveRoute(
                          path: 'shell-inherited',
                          builder: (context, state) =>
                              const Scaffold(body: Text('shell-inherited')),
                        ),
                        AdaptiveRoute(
                          path: 'route-override',
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                usedBuilders.add('route-override');
                                return AdaptivePageTransitions.scale()(
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                );
                              },
                          builder: (context, state) =>
                              const Scaffold(body: Text('route-override')),
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
        usedBuilders.clear();

        // Branch child without route transition uses shell transition
        router.pushNamed('/a/shell-inherited');
        await tester.pumpAndSettle();
        expect(find.text('shell-inherited'), findsOneWidget);
        expect(usedBuilders, contains('shell-default'));

        router.pop();
        await tester.pumpAndSettle();
        usedBuilders.clear();

        // Branch child with route transition overrides shell transition
        router.pushNamed('/a/route-override');
        await tester.pumpAndSettle();
        expect(find.text('route-override'), findsOneWidget);
        expect(usedBuilders, contains('route-override'));
        expect(usedBuilders, isNot(contains('shell-default')));

        router.pop();
        await tester.pumpAndSettle();
        usedBuilders.clear();

        // Fullscreen overlay route outside shell uses router defaultTransition
        router.pushNamed('/overlay');
        await tester.pumpAndSettle();
        expect(find.text('overlay'), findsOneWidget);
        expect(usedBuilders, contains('router-default'));

        router.dispose();
      },
    );

    testWidgets(
      'AdaptivePageTransitionType.none completes immediately in a single pump',
      (tester) async {
        await setWidth(tester, 400);
        final router = AdaptiveRouter(
          initialLocation: '/home',
          defaultTransitionType: AdaptivePageTransitionType.none,
          routes: [
            AdaptiveRoute(
              path: '/home',
              builder: (context, state) => const Scaffold(body: Text('home')),
              routes: [
                AdaptiveRoute(
                  path: 'instant',
                  builder: (context, state) =>
                      const Scaffold(body: Text('instant-page')),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump();
        expect(find.text('home'), findsOneWidget);

        router.pushNamed('/home/instant');
        await tester.pump();
        await tester.pump();
        expect(find.text('instant-page'), findsOneWidget);

        router.dispose();
      },
    );

    testWidgets(
      'custom transitionDuration, reverseTransitionDuration, and curves work with PopScope & onExit',
      (tester) async {
        await setWidth(tester, 400);
        var exitChecks = 0;
        final router = AdaptiveRouter(
          initialLocation: '/home',
          routes: [
            AdaptiveRoute(
              path: '/home',
              builder: (context, state) => const Scaffold(body: Text('home')),
              routes: [
                AdaptiveRoute(
                  path: 'custom',
                  transitionType: AdaptivePageTransitionType.flipHorizontal,
                  transitionDuration: const Duration(milliseconds: 250),
                  reverseTransitionDuration: const Duration(milliseconds: 150),
                  transitionCurve: Curves.easeInOut,
                  reverseTransitionCurve: Curves.easeOut,
                  onExit: (context, state) {
                    exitChecks++;
                    return true;
                  },
                  builder: (context, state) =>
                      const Scaffold(body: Text('custom-flip')),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        router.pushNamed('/home/custom');
        await tester.pumpAndSettle();
        expect(find.text('custom-flip'), findsOneWidget);

        final popped = await router.maybePop();
        await tester.pumpAndSettle();
        expect(popped, isTrue);
        expect(exitChecks, 1);
        expect(find.text('home'), findsOneWidget);

        router.dispose();
      },
    );

    testWidgets(
      'wide-screen 2-column mode animates right pane entrance on depth 1->2 and 2->2 replacement',
      (tester) async {
        await setWidth(tester, 1000);
        final router = AdaptiveRouter(
          initialLocation: '/home',
          routes: [
            AdaptiveShellRoute(
              builder: (context, shell, child) => Scaffold(body: child),
              branches: [
                AdaptiveBranch(
                  routes: [
                    AdaptiveRoute(
                      path: '/home',
                      builder: (context, state) =>
                          const Scaffold(body: Text('left-home')),
                      routes: [
                        AdaptiveRoute(
                          path: 'a',
                          transitionType: AdaptivePageTransitionType.scale,
                          builder: (context, state) =>
                              const Scaffold(body: Text('right-a')),
                        ),
                        AdaptiveRoute(
                          path: 'b',
                          builder: (context, state) =>
                              const Scaffold(body: Text('right-b')),
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
        expect(find.text('left-home'), findsOneWidget);

        // Push right-a (depth 1 -> 2 with ScaleTransition)
        router.pushNamed('/home/a');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(ScaleTransition), findsWidgets);
        await tester.pumpAndSettle();
        expect(find.text('right-a'), findsOneWidget);

        // Replace right-a with right-b (depth 2 -> 2 with default right-pane slide+fade)
        router.pushNamedAndRemoveUntil(
          '/home/b',
          (m) => m.matchedLocation == '/home',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(FractionalTranslation), findsWidgets);
        await tester.pumpAndSettle();
        expect(find.text('right-b'), findsOneWidget);

        router.dispose();
      },
    );
  });
}
