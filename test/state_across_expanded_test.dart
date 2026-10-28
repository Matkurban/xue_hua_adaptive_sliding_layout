import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

/// Counts how often each probe `State` was created (`initState`).
final Map<String, int> inits = {};

/// Page with a counter, a text field and a scrollable list. All of it lives in
/// the `State`, which is exactly what must survive a layout change.
class _Probe extends StatefulWidget {
  const _Probe(this.name);
  final String name;
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int n = 0;
  final text = TextEditingController();
  final scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    inits[widget.name] = (inits[widget.name] ?? 0) + 1;
  }

  @override
  void dispose() {
    text.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = AdaptiveRouter.of(context);
    return Scaffold(
      body: Column(
        children: [
          Wrap(
            children: [
              TextButton(
                onPressed: () => setState(() => n++),
                child: Text('${widget.name}-count-$n'),
              ),
              TextButton(
                onPressed: () => nav.pushNamed('/products/${widget.name}/more'),
                child: Text('${widget.name}-open-more'),
              ),
              TextButton(
                onPressed: () => nav.pop(),
                child: Text('${widget.name}-back'),
              ),
            ],
          ),
          TextField(key: Key('${widget.name}-field'), controller: text),
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
}

AdaptiveRouter _router() => AdaptiveRouter(
  initialLocation: '/products',
  routes: [
    AdaptiveShellRoute(
      builder: (context, shell, child) => shell.isCompact
          ? Scaffold(
              body: child,
              bottomNavigationBar: const SizedBox(
                height: 56,
                child: Text('bottom-bar'),
              ),
            )
          : Scaffold(
              body: Row(
                children: [
                  const SizedBox(width: 60, child: Text('rail')),
                  Expanded(child: child),
                ],
              ),
            ),
      branches: [
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/products',
              builder: (context, state) => Scaffold(
                body: Column(
                  children: [
                    TextButton(
                      onPressed: () =>
                          AdaptiveRouter.of(context).pushNamed('/products/a'),
                      child: const Text('open-a'),
                    ),
                    TextButton(
                      onPressed: () =>
                          AdaptiveShellScope.of(context).goBranch(1),
                      child: const Text('go-account'),
                    ),
                  ],
                ),
              ),
              routes: [
                AdaptiveRoute(
                  path: ':id',
                  builder: (context, state) =>
                      _Probe(state.pathParameters['id']!),
                  routes: [
                    AdaptiveRoute(
                      path: 'more',
                      builder: (context, state) =>
                          _Probe('${state.pathParameters['id']}-more'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/account',
              builder: (context, state) => Scaffold(
                body: TextButton(
                  onPressed: () => AdaptiveShellScope.of(context).goBranch(0),
                  child: const Text('go-products'),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

Future<void> _size(WidgetTester t, double w) async {
  t.view.physicalSize = Size(w, 800);
  await t.pumpAndSettle();
}

Future<AdaptiveRouter> _start(WidgetTester t, double w) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(w, 800);
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  inits.clear();
  final router = _router();
  await t.pumpWidget(MaterialApp.router(routerConfig: router));
  await t.pumpAndSettle();
  return router;
}

void main() {
  // 0 compact, 1 medium, 2 expanded
  const widths = [400.0, 700.0, 1000.0];

  for (final from in widths) {
    for (final to in widths) {
      if (from == to) continue;
      testWidgets('counter, text and scroll survive $from -> $to -> $from', (
        tester,
      ) async {
        final router = await _start(tester, from);
        await tester.tap(find.text('open-a'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('a-count-0'));
        await tester.pump();
        await tester.tap(find.text('a-count-1'));
        await tester.pump();
        await tester.enterText(find.byKey(const Key('a-field')), 'hello');
        await tester.drag(
          find.byKey(const Key('a-list')),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
        final offset = tester
            .state<ScrollableState>(
              find.descendant(
                of: find.byKey(const Key('a-list')),
                matching: find.byType(Scrollable),
              ),
            )
            .position
            .pixels;
        expect(offset, greaterThan(100));

        for (final w in [to, from]) {
          await _size(tester, w);
          expect(
            find.text('a-count-2'),
            findsOneWidget,
            reason: 'counter at $w',
          );
          expect(find.text('hello'), findsOneWidget, reason: 'text at $w');
          final now = tester
              .state<ScrollableState>(
                find.descendant(
                  of: find.byKey(const Key('a-list')),
                  matching: find.byType(Scrollable),
                ),
              )
              .position
              .pixels;
          expect(now, offset, reason: 'scroll at $w');
          expect(router.matches.value.last?.matchedLocation, '/products/a');
        }
        expect(inits['a'], 1, reason: 'State must be created exactly once');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('sweep through every width in one go keeps State', (
    tester,
  ) async {
    await _start(tester, 1000);
    await tester.tap(find.text('open-a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('a-count-0'));
    await tester.pump();
    for (final w in [
      900.0,
      839.0,
      700.0,
      601.0,
      599.0,
      400.0,
      599.0,
      601.0,
      839.0,
      840.0,
      1000.0,
    ]) {
      await _size(tester, w);
      expect(find.text('a-count-1'), findsOneWidget, reason: 'at $w');
    }
    expect(inits['a'], 1);
  });

  testWidgets('resize while the push animation is running', (tester) async {
    for (final pair in [
      (1000.0, 400.0),
      (400.0, 1000.0),
      (700.0, 400.0),
      (400.0, 700.0),
      (700.0, 1000.0),
    ]) {
      final router = await _start(tester, pair.$1);
      await tester.tap(find.text('open-a'));
      await tester.pump(const Duration(milliseconds: 80)); // mid-transition
      tester.view.physicalSize = Size(pair.$2, 800);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pumpAndSettle();
      expect(find.text('a-count-0'), findsOneWidget, reason: '$pair');
      expect(router.matches.value.last?.matchedLocation, '/products/a');
      expect(inits['a'], 1, reason: '$pair');
      expect(tester.takeException(), isNull, reason: '$pair');
      // and the page can still be popped with the back button
      await tester.tap(find.text('a-back'));
      await tester.pumpAndSettle();
      expect(router.matches.value.last?.matchedLocation, '/products');
    }
  });

  testWidgets('resize while the pop animation is running', (tester) async {
    for (final pair in [(1000.0, 400.0), (400.0, 1000.0), (700.0, 400.0)]) {
      final router = await _start(tester, pair.$1);
      await tester.tap(find.text('open-a'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('a-back'));
      await tester.pump(const Duration(milliseconds: 80));
      tester.view.physicalSize = Size(pair.$2, 800);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(
        router.matches.value.last?.matchedLocation,
        '/products',
        reason: '$pair',
      );
      expect(find.text('open-a'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$pair');
    }
  });

  testWidgets('deep stack with several panes keeps every page State', (
    tester,
  ) async {
    final router = await _start(tester, 1000);
    await tester.tap(find.text('open-a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('a-count-0'));
    await tester.pump();
    await tester.tap(find.text('a-open-more'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('a-more-count-0'));
    await tester.pump();
    await tester.tap(find.text('a-more-count-1'));
    await tester.pump();
    for (final w in [700.0, 400.0, 1000.0, 400.0, 700.0, 1000.0]) {
      await _size(tester, w);
      expect(
        router.matches.value.last?.matchedLocation,
        '/products/a/more',
        reason: 'at $w',
      );
      // at compact / medium only the top page is visible; go back to read the other
    }
    expect(inits['a-more'], 1);
    expect(inits['a'], 1);
    expect(find.text('a-more-count-2'), findsOneWidget);
    // pop to the lower page: its State is still alive and keeps its count
    await tester.tap(find.text('a-more-back'));
    await tester.pumpAndSettle();
    expect(find.text('a-count-1'), findsOneWidget);
    expect(inits['a'], 1);
  });

  testWidgets('multi-branch tabs: State survives resize on each tab', (
    tester,
  ) async {
    final router = await _start(tester, 1000);
    await tester.tap(find.text('open-a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('a-count-0'));
    await tester.pump();
    await tester.tap(find.text('a-count-1'));
    await tester.pump();
    for (final w in [400.0, 700.0, 1000.0]) {
      await _size(tester, w);
      expect(
        find.text('a-count-2'),
        findsOneWidget,
        reason: 'products tab at $w',
      );
    }
    expect(inits['a'], 1);
    await tester.tap(find.text('a-back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('go-account'));
    await tester.pumpAndSettle();
    expect(router.currentBranch.value, 1);
    for (final w in [400.0, 1000.0, 700.0]) {
      await _size(tester, w);
      expect(find.text('go-products'), findsOneWidget);
      expect(router.currentBranch.value, 1);
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.text('go-products'));
    await tester.pumpAndSettle();
    expect(router.currentBranch.value, 0);
  });
}
