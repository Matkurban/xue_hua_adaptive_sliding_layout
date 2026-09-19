import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_router.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/match.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/navigation.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/route.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/route_state.dart';

Widget _page(BuildContext context, AdaptiveRouteState state) {
  return Text(state.matchedLocation, textDirection: TextDirection.ltr);
}

List<String> _locs(AdaptiveRouteMatchList list) {
  return [for (final match in list.matches) match.matchedLocation];
}

List<AdaptiveRouteBase> _routes() {
  return [
    AdaptiveRoute(path: '/login', fullscreen: true, builder: _page),
    AdaptiveRoute(
      path: '/photo/:id',
      name: 'photo',
      fullscreen: true,
      builder: _page,
    ),
    AdaptiveShellRoute(
      builder: (context, shell, child) => child,
      branches: [
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/mail',
              builder: _page,
              routes: [
                AdaptiveRoute(
                  path: ':folder',
                  builder: _page,
                  routes: [AdaptiveRoute(path: ':threadId', builder: _page)],
                ),
              ],
            ),
          ],
        ),
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/contacts',
              builder: _page,
              routes: [AdaptiveRoute(path: ':id', builder: _page)],
            ),
          ],
        ),
      ],
    ),
  ];
}

void main() {
  late RouteRegistry registry;
  late NavigationEngine engine;

  setUp(() {
    registry = RouteRegistry(_routes());
    engine = NavigationEngine(registry);
  });

  AdaptiveRouteMatchList at(String location) =>
      registry.match(Uri.parse(location));

  group('pushNamed', () {
    test('prefix extends the stack', () {
      var stack = at('/mail');
      stack = engine.pushNamed(stack, '/mail/inbox');
      expect(_locs(stack), ['/mail', '/mail/inbox']);
      stack = engine.pushNamed(stack, '/mail/inbox/42');
      expect(_locs(stack), ['/mail', '/mail/inbox', '/mail/inbox/42']);
    });

    test('same location is a no-op', () {
      var stack = at('/mail/inbox');
      stack = engine.pushNamed(stack, '/mail/inbox');
      expect(_locs(stack), ['/mail', '/mail/inbox']);
    });

    test('non-prefix appends the leaf', () {
      var stack = at('/mail/inbox/41');
      stack = engine.pushNamed(stack, '/mail/inbox/42');
      expect(_locs(stack), [
        '/mail',
        '/mail/inbox',
        '/mail/inbox/41',
        '/mail/inbox/42',
      ]);
      expect(stack.matches.last.isImperative, isTrue);
      expect(stack.uri.path, '/mail/inbox/42');
    });

    test('fullscreen stacks on the current branch', () {
      var stack = at('/mail/inbox');
      stack = engine.pushNamed(stack, '/photo/9', arguments: 'file');
      expect(_locs(stack), ['/mail', '/mail/inbox', '/photo/9']);
      expect(stack.overlayMatches, hasLength(1));
      expect(stack.overlayMatches.single.arguments, 'file');
      expect(stack.uri.path, '/photo/9');
    });

    test('other branch replaces the stack', () {
      var stack = at('/mail/inbox/42');
      stack = engine.pushNamed(stack, '/contacts/7');
      expect(_locs(stack), ['/contacts', '/contacts/7']);
      expect(stack.branchIndex, 1);
    });
  });

  group('pushReplacementNamed', () {
    test('swaps the top pane', () {
      var stack = at('/mail/inbox/41');
      stack = engine.pushReplacementNamed(stack, '/mail/inbox/42');
      expect(_locs(stack), ['/mail', '/mail/inbox', '/mail/inbox/42']);
    });
  });

  group('pushNamedAndRemoveUntil', () {
    test('false predicate rebuilds from URL', () {
      var stack = at('/mail/inbox/42');
      stack = engine.pushNamedAndRemoveUntil(
        stack,
        '/mail/inbox/7',
        (_) => false,
      );
      expect(_locs(stack), ['/mail', '/mail/inbox', '/mail/inbox/7']);
    });

    test('stops at matching page then pushes', () {
      var stack = at('/mail/inbox/42');
      stack = engine.pushNamedAndRemoveUntil(
        stack,
        '/mail/inbox/9',
        (match) => match.matchedLocation == '/mail/inbox',
      );
      expect(_locs(stack), ['/mail', '/mail/inbox', '/mail/inbox/9']);
    });
  });

  group('pop', () {
    test('pops overlay first', () {
      var stack = at('/mail/inbox');
      stack = engine.pushNamed(stack, '/photo/9');
      final future = stack.overlayMatches.single.completer!.future;
      stack = engine.pop(stack, 'done');
      expect(_locs(stack), ['/mail', '/mail/inbox']);
      expect(future, completion('done'));
    });

    test('pops branch top', () {
      var stack = at('/mail/inbox/42');
      stack = engine.pop(stack);
      expect(_locs(stack), ['/mail', '/mail/inbox']);
    });

    test('root cannot pop', () {
      final stack = at('/mail');
      expect(engine.canPop(stack), isFalse);
      expect(_locs(engine.pop(stack)), ['/mail']);
    });
  });

  group('popUntil / popAndPushNamed', () {
    test('popUntil stops at the predicate', () {
      var stack = at('/mail/inbox/42');
      stack = engine.popUntil(
        stack,
        (match) => match.matchedLocation == '/mail',
      );
      expect(_locs(stack), ['/mail']);
    });

    test('popAndPushNamed pops then pushes', () {
      var stack = at('/mail/inbox');
      stack = engine.popAndPushNamed(stack, '/mail/inbox/3');
      expect(_locs(stack), ['/mail', '/mail/inbox', '/mail/inbox/3']);
    });
  });

  group('goBranch', () {
    test('rebuilds the target branch from location', () {
      final stack = engine.goBranch(at('/mail/inbox'), location: '/contacts');
      expect(_locs(stack), ['/contacts']);
      expect(stack.branchIndex, 1);
    });

    test('restores stored matches including arguments', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final router = AdaptiveRouter(
        routes: _routes(),
        initialLocation: '/mail',
      );
      await router.applyParsed(router.registry.match(Uri.parse('/mail')));
      final payload = Object();
      // Don't await: pushNamed's Future completes on pop, not on the push.
      router.pushNamed('/mail/inbox/42', arguments: payload);
      await Future<void>.delayed(Duration.zero);
      final leaf = router.matches.value.last!;
      expect(identical(leaf.arguments, payload), isTrue);
      router.goBranch(1);
      router.goBranch(0);
      expect(identical(router.matches.value.last, leaf), isTrue);
      expect(identical(router.matches.value.last!.arguments, payload), isTrue);
    });
  });
}
