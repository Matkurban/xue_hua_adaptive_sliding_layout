import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

SlidingPane _pane(String name, {Widget? child}) {
  return SlidingPane(
    key: ValueKey<String>(name),
    title: signal(name),
    child: child ?? ColoredBox(color: Colors.grey, child: Text(name)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('clampLeftPaneFraction', () {
    test('stays inside 0.3 and 0.7 by default', () {
      expect(SlidingPaneViewport.clampLeftPaneFraction(0.5), 0.5);
      expect(SlidingPaneViewport.clampLeftPaneFraction(0.1), 0.3);
      expect(SlidingPaneViewport.clampLeftPaneFraction(0.9), 0.7);
    });
  });

  group('SlidingPaneViewport resize', () {
    testWidgets('default 800-wide split is 400 / 400', (tester) async {
      await tester.pumpWidget(
        _ResizeHarness(panes: [_pane('Root'), _pane('A')]),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(find.byKey(SlidingPaneViewport.visibleLeftPaneKey))
            .width,
        400,
      );
      expect(
        tester
            .getSize(find.byKey(SlidingPaneViewport.visibleRightPaneKey))
            .width,
        400,
      );
      expect(find.byKey(SlidingPaneViewport.resizeHandleKey), findsOneWidget);
    });

    testWidgets('left pane width tracks pointer x', (tester) async {
      var rightTaps = 0;
      await tester.pumpWidget(
        _ResizeHarness(
          panes: [
            _pane('Root'),
            _pane(
              'A',
              child: Center(
                child: TextButton(
                  onPressed: () => rightTaps++,
                  child: const Text('right-btn'),
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(SlidingPaneViewport.resizeHandleKey),
        const Offset(80, 0),
        touchSlopX: 0,
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .getSize(find.byKey(SlidingPaneViewport.visibleLeftPaneKey))
            .width,
        480,
      );
      expect(
        tester
            .getSize(find.byKey(SlidingPaneViewport.visibleRightPaneKey))
            .width,
        320,
      );

      await tester.tap(find.text('right-btn'));
      await tester.pump();
      expect(rightTaps, 1);
    });

    testWidgets('dragging left clamps at 0.3 (240px on 800)', (tester) async {
      await tester.pumpWidget(
        _ResizeHarness(panes: [_pane('Root'), _pane('A')]),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(SlidingPaneViewport.resizeHandleKey),
        const Offset(-400, 0),
        touchSlopX: 0,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(find.byKey(SlidingPaneViewport.visibleLeftPaneKey))
            .width,
        240,
      );
      expect(
        tester
            .getSize(find.byKey(SlidingPaneViewport.visibleRightPaneKey))
            .width,
        560,
      );
    });

    testWidgets('dragging right clamps at 0.7 so right pane stays 30%', (
      tester,
    ) async {
      await tester.pumpWidget(
        _ResizeHarness(panes: [_pane('Root'), _pane('A')]),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(SlidingPaneViewport.resizeHandleKey),
        const Offset(400, 0),
        touchSlopX: 0,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(find.byKey(SlidingPaneViewport.visibleLeftPaneKey))
            .width,
        560,
      );
      expect(
        tester
            .getSize(find.byKey(SlidingPaneViewport.visibleRightPaneKey))
            .width,
        240,
      );
    });

    testWidgets('visibleCount 1 has no resize handle', (tester) async {
      await tester.pumpWidget(
        _ResizeHarness(panes: [_pane('Root'), _pane('A')], visibleCount: 1),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(SlidingPaneViewport.resizeHandleKey), findsNothing);
      expect(tester.getSize(find.byType(SlidingPaneViewport)).width, 800);
    });
  });
}

class _ResizeHarness extends StatelessWidget {
  const _ResizeHarness({required this.panes, this.visibleCount = 2});

  final List<SlidingPane> panes;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 800,
          height: 600,
          child: SlidingPaneViewport(panes: panes, visibleCount: visibleCount),
        ),
      ),
    );
  }
}
