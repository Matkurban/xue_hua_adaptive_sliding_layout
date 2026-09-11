import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('clampLeftPaneFraction', () {
    test('stays inside 0.3 and 0.7 by default', () {
      expect(SlidingWindowViewport.clampLeftPaneFraction(0.5), 0.5);
      expect(SlidingWindowViewport.clampLeftPaneFraction(0.1), 0.3);
      expect(SlidingWindowViewport.clampLeftPaneFraction(0.9), 0.7);
    });
  });

  group('SlidingWindowViewport resize', () {
    late SlidingWindowController controller;

    setUp(() {
      controller = SlidingWindowController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('default 800-wide split is 400 / 400', (tester) async {
      _pushDepth2(controller);
      await tester.pumpWidget(_ResizeHarness(controller: controller));
      await tester.pumpAndSettle();

      expect(
        tester
            .getSize(find.byKey(SlidingWindowViewport.visibleLeftPaneKey))
            .width,
        400,
      );
      expect(
        tester
            .getSize(find.byKey(SlidingWindowViewport.visibleRightPaneKey))
            .width,
        400,
      );
      expect(find.byKey(SlidingWindowViewport.resizeHandleKey), findsOneWidget);
    });

    testWidgets('left pane width tracks pointer x', (tester) async {
      _pushDepth2(controller);
      await tester.pumpWidget(_ResizeHarness(controller: controller));
      await tester.pumpAndSettle();

      final viewportTopLeft = tester.getTopLeft(
        find.byType(SlidingWindowViewport),
      );
      final handleCenter = tester.getCenter(
        find.byKey(SlidingWindowViewport.resizeHandleKey),
      );
      await tester.dragFrom(handleCenter, const Offset(80, 0), touchSlopX: 0);
      await tester.pumpAndSettle();

      expect(
        tester
            .getSize(find.byKey(SlidingWindowViewport.visibleLeftPaneKey))
            .width,
        closeTo(handleCenter.dx - viewportTopLeft.dx + 80, 1),
      );
    });

    testWidgets(
      'dragging handle right widens left pane and right button stays tappable',
      (tester) async {
        var rightTaps = 0;
        controller.ensureRoot(
          name: 'Root',
          builder: (_) => const ColoredBox(color: Colors.grey),
        );
        controller.push(
          (_) => Center(
            child: TextButton(
              onPressed: () => rightTaps++,
              child: const Text('right-btn'),
            ),
          ),
          name: 'A',
        );

        await tester.pumpWidget(_ResizeHarness(controller: controller));
        await tester.pumpAndSettle();

        await tester.drag(
          find.byKey(SlidingWindowViewport.resizeHandleKey),
          const Offset(80, 0),
          touchSlopX: 0,
        );
        await tester.pumpAndSettle();

        expect(
          tester
              .getSize(find.byKey(SlidingWindowViewport.visibleLeftPaneKey))
              .width,
          480,
        );
        expect(
          tester
              .getSize(find.byKey(SlidingWindowViewport.visibleRightPaneKey))
              .width,
          320,
        );

        await tester.tap(find.text('right-btn'));
        await tester.pump();
        expect(rightTaps, 1);
      },
    );

    testWidgets('dragging left clamps at 0.3 (240px on 800)', (tester) async {
      _pushDepth2(controller);
      await tester.pumpWidget(_ResizeHarness(controller: controller));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(SlidingWindowViewport.resizeHandleKey),
        const Offset(-400, 0),
        touchSlopX: 0,
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .getSize(find.byKey(SlidingWindowViewport.visibleLeftPaneKey))
            .width,
        240,
      );
      expect(
        tester
            .getSize(find.byKey(SlidingWindowViewport.visibleRightPaneKey))
            .width,
        560,
      );
    });

    testWidgets('dragging right clamps at 0.7 so right pane stays 30%', (
      tester,
    ) async {
      _pushDepth2(controller);
      await tester.pumpWidget(_ResizeHarness(controller: controller));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(SlidingWindowViewport.resizeHandleKey),
        const Offset(400, 0),
        touchSlopX: 0,
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .getSize(find.byKey(SlidingWindowViewport.visibleLeftPaneKey))
            .width,
        560,
      );
      expect(
        tester
            .getSize(find.byKey(SlidingWindowViewport.visibleRightPaneKey))
            .width,
        240,
      );
    });

    testWidgets('visibleCount 1 has no resize handle', (tester) async {
      _pushDepth2(controller);
      await tester.pumpWidget(
        _ResizeHarness(controller: controller, visibleCount: 1),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(SlidingWindowViewport.resizeHandleKey), findsNothing);
      expect(tester.getSize(find.byType(SlidingWindowViewport)).width, 800);
    });
  });
}

void _pushDepth2(SlidingWindowController controller) {
  controller.ensureRoot(
    name: 'Root',
    builder: (_) => const ColoredBox(color: Colors.grey),
  );
  controller.push((_) => const ColoredBox(color: Colors.blue), name: 'A');
}

class _ResizeHarness extends StatelessWidget {
  const _ResizeHarness({required this.controller, this.visibleCount = 2});

  final SlidingWindowController controller;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 800,
          height: 600,
          child: SlidingWindowScope(
            controller: controller,
            child: SlidingWindowViewport(
              controller: controller,
              visibleCount: visibleCount,
            ),
          ),
        ),
      ),
    );
  }
}
