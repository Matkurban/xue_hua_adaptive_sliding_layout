import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

final Map<String, int> inits = {};
final Map<String, int> builds = {};

class _Page extends StatefulWidget {
  const _Page(this.name);
  final String name;
  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  int n = 0;
  @override
  void initState() {
    super.initState();
    inits[widget.name] = (inits[widget.name] ?? 0) + 1;
  }

  @override
  Widget build(BuildContext context) {
    builds[widget.name] = (builds[widget.name] ?? 0) + 1;
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () => setState(() => n++),
            child: Text('${widget.name}-n$n'),
          ),
          TextButton(
            onPressed: () => AdaptiveRouter.of(context).pushNamed('/a/x'),
            child: Text('${widget.name}-open'),
          ),
        ],
      ),
    );
  }
}

AdaptiveRouter _router({String initial = '/a'}) => AdaptiveRouter(
  initialLocation: initial,
  routes: [
    AdaptiveShellRoute(
      builder: (context, shell, child) => Scaffold(
        body: child,
        bottomNavigationBar: shell.isCompact
            ? const SizedBox(height: 56, child: Text('bar'))
            : null,
      ),
      branches: [
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/a',
              builder: (c, s) => const _Page('a'),
              routes: [
                AdaptiveRoute(path: 'x', builder: (c, s) => const _Page('ax')),
              ],
            ),
          ],
        ),
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(path: '/b', builder: (c, s) => const _Page('b')),
          ],
        ),
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(path: '/c', builder: (c, s) => const _Page('c')),
          ],
        ),
      ],
    ),
  ],
);

Future<AdaptiveRouter> _start(
  WidgetTester t,
  double w, {
  String initial = '/a',
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(w, 800);
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  inits.clear();
  builds.clear();
  final router = _router(initial: initial);
  await t.pumpWidget(MaterialApp.router(routerConfig: router));
  await t.pumpAndSettle();
  return router;
}

void main() {
  for (final width in [400.0, 700.0, 1000.0]) {
    testWidgets(
      'unopened branches are not built; first visit builds once (width $width)',
      (tester) async {
        final router = await _start(tester, width);
        expect(inits['a'], 1);
        expect(inits['b'], isNull);
        expect(inits['c'], isNull);
        expect(builds['b'], isNull);

        // lots of shell rebuilds while b / c are unopened: push, pop, resize
        await tester.tap(find.text('a-open'));
        await tester.pumpAndSettle();
        router.maybePop();
        await tester.pumpAndSettle();
        for (final w in [width == 400 ? 1000.0 : 400.0, width]) {
          tester.view.physicalSize = Size(w, 800);
          await tester.pumpAndSettle();
        }
        expect(
          inits['b'],
          isNull,
          reason: 'b must not be initState-d before it is visited',
        );
        expect(inits['c'], isNull);
        expect(builds['b'], isNull);
        expect(inits['a'], 1);

        router.goBranch(1);
        await tester.pumpAndSettle();
        expect(find.text('b-n0'), findsOneWidget);
        expect(inits['b'], 1);
        expect(inits['c'], isNull, reason: 'c is still unopened');
        final bBuilds = builds['b']!;

        await tester.tap(find.text('b-n0'));
        await tester.pump();
        for (var i = 0; i < 3; i++) {
          router.goBranch(0);
          await tester.pumpAndSettle();
          router.goBranch(1);
          await tester.pumpAndSettle();
          expect(
            find.text('b-n1'),
            findsOneWidget,
            reason: 'State kept, round $i',
          );
        }
        expect(inits['b'], 1);
        expect(inits['a'], 1);
        expect(inits['c'], isNull);
        expect(
          builds['b']! - bBuilds,
          lessThan(12),
          reason: 'no rebuild storm',
        );

        router.goBranch(2);
        await tester.pumpAndSettle();
        expect(inits['c'], 1);
        expect(inits['b'], 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('deep link into another branch builds only that branch', (
    tester,
  ) async {
    await _start(tester, 400, initial: '/b');
    expect(inits['b'], 1);
    expect(inits['a'], isNull);
    expect(inits['c'], isNull);
  });

  testWidgets(
    'goBranch with initialLocation on an unopened branch builds it once',
    (tester) async {
      final router = await _start(tester, 400);
      router.goBranch(2, initialLocation: true);
      await tester.pumpAndSettle();
      expect(find.text('c-n0'), findsOneWidget);
      expect(inits['c'], 1);
      expect(inits['b'], isNull);
    },
  );
}
