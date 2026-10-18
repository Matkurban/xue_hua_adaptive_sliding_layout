import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

final Map<String, int> inits = {};
final Map<String, int> disposes = {};

/// Detail pages use the default `hidesBottomBarWhenPushed: true`, so on compact
/// screens they live in the cover layer, not in the branch Navigator.
class _Page extends StatefulWidget {
  const _Page(this.name, {this.opens});
  final String name;
  final String? opens;
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
    appBar: widget.opens == null ? AppBar(leading: const BackButton()) : null,
    body: Column(
      children: [
        Wrap(
          children: [
            TextButton(
              onPressed: () => setState(() => n++),
              child: Text('${widget.name}-n$n'),
            ),
            if (widget.opens != null)
              TextButton(
                onPressed: () =>
                    AdaptiveRouter.of(context).pushNamed(widget.opens!),
                child: Text('${widget.name}-open'),
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
      builder: (context, shell, child) => shell.isCompact
          ? AdaptiveShellChrome(
              bottomNavigationBar: (context) =>
                  const SizedBox(height: 56, child: Text('bar')),
              child: child,
            )
          : Scaffold(body: child),
      branches: [
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/a',
              builder: (c, s) => const _Page('a', opens: '/a/x'),
              routes: [
                AdaptiveRoute(path: 'x', builder: (c, s) => const _Page('ax')),
              ],
            ),
          ],
        ),
        AdaptiveBranch(
          routes: [
            AdaptiveRoute(
              path: '/b',
              builder: (c, s) => const _Page('b', opens: '/b/x'),
              routes: [
                AdaptiveRoute(path: 'x', builder: (c, s) => const _Page('bx')),
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

Future<AdaptiveRouter> _start(WidgetTester t, double w) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(w, 800);
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  inits.clear();
  disposes.clear();
  final router = _router();
  await t.pumpWidget(MaterialApp.router(routerConfig: router));
  await t.pumpAndSettle();
  return router;
}

Future<void> _size(WidgetTester t, double w) async {
  t.view.physicalSize = Size(w, 800);
  await t.pumpAndSettle();
}

/// Opens the detail page of the current branch and puts state into it.
Future<double> _dirty(WidgetTester t, String root, String detail) async {
  await t.tap(find.text('$root-open'));
  await t.pumpAndSettle();
  await t.tap(find.text('$detail-n0'));
  await t.pump();
  await t.drag(find.byKey(Key('$detail-list')), const Offset(0, -300));
  await t.pumpAndSettle();
  final o = _offset(t, detail);
  expect(o, greaterThan(100));
  return o;
}

void main() {
  testWidgets(
    'compact: detail pages keep State when switching tabs back and forth',
    (tester) async {
      final router = await _start(tester, 400);
      final ao = await _dirty(tester, 'a', 'ax');
      expect(router.location.value, '/a/x');
      router.goBranch(1);
      await tester.pumpAndSettle();
      expect(find.text('b-n0'), findsOneWidget);
      expect(
        find.text('ax-n1'),
        findsNothing,
        reason: 'parked page must not show',
      );
      final bo = await _dirty(tester, 'b', 'bx');
      final snapshot = Map<String, int>.of(inits);
      for (var i = 0; i < 3; i++) {
        router.goBranch(0);
        await tester.pumpAndSettle();
        expect(router.location.value, '/a/x');
        expect(find.text('ax-n1'), findsOneWidget, reason: 'round $i');
        expect(find.text('bx-n1'), findsNothing);
        expect(_offset(tester, 'ax'), ao);
        router.goBranch(1);
        await tester.pumpAndSettle();
        expect(router.location.value, '/b/x');
        expect(find.text('bx-n1'), findsOneWidget, reason: 'round $i');
        expect(find.text('ax-n1'), findsNothing);
        expect(_offset(tester, 'bx'), bo);
      }
      expect(inits, snapshot);
      expect(disposes['ax'], isNull);
      expect(disposes['bx'], isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact: back button and system back still pop the visible detail',
    (tester) async {
      final router = await _start(tester, 400);
      await _dirty(tester, 'a', 'ax');
      router.goBranch(1);
      await tester.pumpAndSettle();
      await _dirty(tester, 'b', 'bx');
      router.goBranch(0);
      await tester.pumpAndSettle();
      // AppBar back on the revived detail page
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(router.location.value, '/a');
      expect(disposes['ax'], 1);
      expect(find.text('a-n0'), findsOneWidget);
      expect(find.text('bar'), findsOneWidget, reason: 'bottom bar is back');
      // other tab's detail is untouched
      router.goBranch(1);
      await tester.pumpAndSettle();
      expect(find.text('bx-n1'), findsOneWidget);
      // system back pops it
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(router.location.value, '/b');
      expect(disposes['bx'], 1);
      expect(find.text('b-n0'), findsOneWidget);
      // reopening gives a fresh State
      await tester.tap(find.text('b-open'));
      await tester.pumpAndSettle();
      expect(inits['bx'], 2);
      expect(find.text('bx-n0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'parked pages survive breakpoint crossings and come back intact',
    (tester) async {
      final router = await _start(tester, 400);
      final ao = await _dirty(tester, 'a', 'ax');
      router.goBranch(1);
      await tester.pumpAndSettle();
      final bo = await _dirty(tester, 'b', 'bx');
      final snapshot = Map<String, int>.of(inits);
      router.goBranch(0); // bx is now parked
      await tester.pumpAndSettle();
      for (final w in [700.0, 1000.0, 700.0, 400.0, 1000.0, 400.0]) {
        await _size(tester, w);
        expect(router.location.value, '/a/x', reason: 'at $w');
        expect(find.text('ax-n1'), findsOneWidget, reason: 'at $w');
        expect(tester.takeException(), isNull, reason: 'at $w');
      }
      expect(_offset(tester, 'ax'), ao);
      router.goBranch(1);
      await tester.pumpAndSettle();
      expect(find.text('bx-n1'), findsOneWidget);
      expect(_offset(tester, 'bx'), bo);
      for (final w in [1000.0, 400.0, 700.0, 400.0]) {
        await _size(tester, w);
        expect(find.text('bx-n1'), findsOneWidget, reason: 'at $w');
      }
      router.goBranch(0);
      await tester.pumpAndSettle();
      expect(find.text('ax-n1'), findsOneWidget);
      expect(inits, snapshot);
      expect(disposes['ax'], isNull);
      expect(disposes['bx'], isNull);
    },
  );

  testWidgets('switching tabs while a detail push animation runs', (
    tester,
  ) async {
    final router = await _start(tester, 400);
    await tester.tap(find.text('a-open'));
    await tester.pump(const Duration(milliseconds: 80));
    router.goBranch(1);
    await tester.pumpAndSettle();
    expect(find.text('b-n0'), findsOneWidget);
    router.goBranch(0);
    await tester.pumpAndSettle();
    expect(router.location.value, '/a/x');
    expect(find.text('ax-n0'), findsOneWidget);
    expect(inits['ax'], 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parked page is not reachable by tap, focus or semantics', (
    tester,
  ) async {
    final router = await _start(tester, 400);
    await tester.tap(find.text('a-open'));
    await tester.pumpAndSettle();
    router.goBranch(1);
    await tester.pumpAndSettle();
    expect(find.text('ax-n0'), findsNothing);
    expect(find.text('ax-n0', skipOffstage: false), findsOneWidget);
    expect(find.bySemanticsLabel('ax-n0'), findsNothing);
    await tester.tap(find.text('b-open'));
    await tester.pumpAndSettle();
    expect(router.location.value, '/b/x');
  });
}
