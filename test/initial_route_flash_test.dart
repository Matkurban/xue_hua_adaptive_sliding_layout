import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'initial /splash route renders on the first frame without flashing errorBuilder',
    (tester) async {
      var errorBuilds = 0;
      var splashBuilds = 0;

      final router = AdaptiveRouter(
        initialLocation: '/splash',
        redirect: (context, state) => null,
        errorBuilder: (context, state) {
          errorBuilds++;
          return Scaffold(body: Center(child: Text('${state.uri}')));
        },
        routes: [
          AdaptiveRoute(path: '/', redirect: (_, _) => '/splash'),
          AdaptiveRoute(
            path: '/splash',
            fullscreen: true,
            builder: (context, state) {
              splashBuilds++;
              return const Scaffold(body: Center(child: Text('splash-page')));
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // First frame must already show SplashPage and never flash errorBuilder.
      expect(errorBuilds, 0);
      expect(find.text('/splash'), findsNothing);
      expect(find.text('splash-page'), findsOneWidget);
      expect(splashBuilds, 1);

      await tester.pumpAndSettle();
      expect(errorBuilds, 0);
      expect(find.text('splash-page'), findsOneWidget);
      expect(splashBuilds, 1);
    },
  );

  testWidgets(
    'synchronous root redirect resolves to /splash on the first frame without errorBuilder',
    (tester) async {
      var errorBuilds = 0;

      final router = AdaptiveRouter(
        initialLocation: '/',
        errorBuilder: (context, state) {
          errorBuilds++;
          return Scaffold(body: Center(child: Text('${state.uri}')));
        },
        routes: [
          AdaptiveRoute(path: '/', redirect: (_, _) => '/splash'),
          AdaptiveRoute(
            path: '/splash',
            fullscreen: true,
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('splash-page'))),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(errorBuilds, 0);
      expect(find.text('/'), findsNothing);
      expect(find.text('/splash'), findsNothing);
      expect(find.text('splash-page'), findsOneWidget);
      expect(router.location.value, '/splash');
    },
  );

  testWidgets(
    'asynchronous redirect does not flash errorBuilder before initial route resolves',
    (tester) async {
      var errorBuilds = 0;
      final gate = Completer<String?>();

      final router = AdaptiveRouter(
        initialLocation: '/splash',
        redirect: (context, state) => gate.future,
        errorBuilder: (context, state) {
          errorBuilds++;
          return Scaffold(body: Center(child: Text('${state.uri}')));
        },
        routes: [
          AdaptiveRoute(path: '/', redirect: (_, _) => '/splash'),
          AdaptiveRoute(
            path: '/splash',
            fullscreen: true,
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('splash-page'))),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Still waiting on async redirect: must NOT render errorBuilder.
      expect(router.isReady, isFalse);
      expect(errorBuilds, 0);
      expect(find.text('/splash'), findsNothing);
      expect(find.text('splash-page'), findsNothing);

      gate.complete(null);
      await tester.pumpAndSettle();

      expect(router.isReady, isTrue);
      expect(errorBuilds, 0);
      expect(find.text('splash-page'), findsOneWidget);
    },
  );

  testWidgets(
    'genuinely unknown initial route still renders errorBuilder once ready',
    (tester) async {
      final router = AdaptiveRouter(
        initialLocation: '/does-not-exist',
        errorBuilder: (context, state) =>
            Scaffold(body: Center(child: Text('404:${state.uri}'))),
        routes: [
          AdaptiveRoute(
            path: '/splash',
            fullscreen: true,
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('splash-page'))),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(router.isReady, isTrue);
      expect(find.text('404:/does-not-exist'), findsOneWidget);
    },
  );
}
