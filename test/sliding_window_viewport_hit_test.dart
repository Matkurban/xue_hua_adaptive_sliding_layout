import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SlidingWindowViewport hit test', () {
    late SlidingWindowController controller;

    setUp(() {
      controller = SlidingWindowController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('depth 3 right pane button is tappable', (tester) async {
      var leftTaps = 0;
      var rightTaps = 0;
      controller.ensureRoot(
        name: 'Root',
        builder: (_) => const ColoredBox(color: Colors.grey),
      );
      controller.push(
        (_) => Center(
          child: TextButton(
            onPressed: () => leftTaps++,
            child: const Text('left-btn'),
          ),
        ),
        name: 'A',
      );
      controller.push(
        (_) => Center(
          child: TextButton(
            onPressed: () => rightTaps++,
            child: const Text('right-btn'),
          ),
        ),
        name: 'B',
      );

      await tester.pumpWidget(_ViewportHarness(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('right-btn'));
      await tester.pump();
      expect(rightTaps, 1);
      expect(leftTaps, 0);
    });

    testWidgets('depth 3 left pane button stays tappable', (tester) async {
      var leftTaps = 0;
      var rightTaps = 0;
      controller.ensureRoot(
        name: 'Root',
        builder: (_) => const ColoredBox(color: Colors.grey),
      );
      controller.push(
        (_) => Center(
          child: TextButton(
            onPressed: () => leftTaps++,
            child: const Text('left-btn'),
          ),
        ),
        name: 'A',
      );
      controller.push(
        (_) => Center(
          child: TextButton(
            onPressed: () => rightTaps++,
            child: const Text('right-btn'),
          ),
        ),
        name: 'B',
      );

      await tester.pumpWidget(_ViewportHarness(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('left-btn'));
      await tester.pump();
      expect(leftTaps, 1);
      expect(rightTaps, 0);
    });
  });
}

class _ViewportHarness extends StatelessWidget {
  const _ViewportHarness({required this.controller});

  final SlidingWindowController controller;

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
              visibleCount: 2,
            ),
          ),
        ),
      ),
    );
  }
}
