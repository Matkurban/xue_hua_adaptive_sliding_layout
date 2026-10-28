import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

final Map<String, int> inits = {};
final Map<String, int> disposes = {};

class _Page extends StatefulWidget {
  const _Page(this.name);
  final String name;
  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  final scroll = ScrollController();
  int n = 0;
  @override
  void initState() {
    super.initState();
    inits[widget.name] = (inits[widget.name] ?? 0) + 1;
  }

  @override
  void dispose() {
    disposes[widget.name] = (disposes[widget.name] ?? 0) + 1;
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Wrap(
          children: [
            TextButton(
              onPressed: () => setState(() => n++),
              child: Text('${widget.name}-n$n'),
            ),
            TextButton(
              onPressed: () => AdaptiveRouter.of(context).pushNamed('/b/x'),
              child: Text('${widget.name}-open-x'),
            ),
            TextButton(
              onPressed: () => AdaptiveRouter.of(context).goBranch(0),
              child: Text('${widget.name}-to-0'),
            ),
            TextButton(
              onPressed: () => AdaptiveRouter.of(context).goBranch(1),
              child: Text('${widget.name}-to-1'),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            key: Key('${widget.name}-list'),
            controller: scroll,
            itemCount: 100,
            itemBuilder: (_, i) =>
                SizedBox(height: 40, child: Text('${widget.name}-row-$i')),
          ),
        ),
      ],
    ),
  );
}

AdaptiveRouter _router() => AdaptiveRouter(
  initialLocation: '/a',
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
            AdaptiveRoute(path: '/a', builder: (c, s) => const _Page('a')),
          ],
        ),
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/b',
              builder: (c, s) => const _Page('b'),
              routes: [
                AdaptiveRoute(
                  path: 'x',
                  hidesBottomBarWhenPushed: false,
                  builder: (c, s) => const _Page('bx'),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

double _offset(WidgetTester t, String name) => t
    .state<ScrollableState>(
      find.descendant(
        of: find.byKey(Key('$name-list')),
        matching: find.byType(Scrollable),
      ),
    )
    .position
    .pixels;

void main() {
  for (final width in [400.0, 700.0, 1000.0]) {
    testWidgets('branch switches keep every page State at width $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      inits.clear();
      disposes.clear();
      final router = _router();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('a-n0'));
      await tester.pump();
      await tester.drag(find.byKey(const Key('a-list')), const Offset(0, -300));
      await tester.pumpAndSettle();
      final aOffset = _offset(tester, 'a');
      expect(aOffset, greaterThan(100));

      router.goBranch(1);
      await tester.pumpAndSettle();
      await tester.tap(find.text('b-n0'));
      await tester.pump();
      await tester.tap(find.text('b-open-x'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('bx-n0'));
      await tester.pump();
      await tester.drag(
        find.byKey(const Key('bx-list')),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      final xOffset = _offset(tester, 'bx');

      for (var round = 0; round < 3; round++) {
        router.goBranch(0);
        await tester.pumpAndSettle();
        expect(find.text('a-n1'), findsOneWidget, reason: 'round $round');
        expect(_offset(tester, 'a'), aOffset, reason: 'round $round');
        router.goBranch(1);
        await tester.pumpAndSettle();
        expect(find.text('bx-n1'), findsOneWidget, reason: 'round $round');
        expect(_offset(tester, 'bx'), xOffset, reason: 'round $round');
        expect(router.matches.value.last?.matchedLocation, '/b/x');
      }
      expect(inits, {'a': 1, 'b': 1, 'bx': 1});
      expect(disposes, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pages that leave every stack are still disposed', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    inits.clear();
    disposes.clear();
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.goBranch(1);
    await tester.pumpAndSettle();
    await tester.tap(find.text('b-open-x'));
    await tester.pumpAndSettle();
    router.maybePop();
    await tester.pumpAndSettle();
    expect(disposes['bx'], 1);
    // opening it again creates a fresh State
    await tester.tap(find.text('b-open-x'));
    await tester.pumpAndSettle();
    expect(inits['bx'], 2);
    expect(find.text('bx-n0'), findsOneWidget);
    expect(inits['a'], 1);
    expect(inits['b'], 1);
  });
}
