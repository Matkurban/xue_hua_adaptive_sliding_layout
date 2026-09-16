import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SlidingPaneViewport hit test', () {
    testWidgets('depth 3 right pane button is tappable', (tester) async {
      var leftTaps = 0;
      var rightTaps = 0;
      await tester.pumpWidget(
        _ViewportHarness(
          panes: [
            _pane('Root'),
            _pane(
              'A',
              child: Center(
                child: TextButton(
                  onPressed: () => leftTaps++,
                  child: const Text('left-btn'),
                ),
              ),
            ),
            _pane(
              'B',
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
      await tester.tap(find.text('right-btn'));
      await tester.pump();
      expect(rightTaps, 1);
      expect(leftTaps, 0);
    });

    testWidgets('depth 3 left pane button stays tappable', (tester) async {
      var leftTaps = 0;
      var rightTaps = 0;
      await tester.pumpWidget(
        _ViewportHarness(
          panes: [
            _pane('Root'),
            _pane(
              'A',
              child: Center(
                child: TextButton(
                  onPressed: () => leftTaps++,
                  child: const Text('left-btn'),
                ),
              ),
            ),
            _pane(
              'B',
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
      await tester.tap(find.text('left-btn'));
      await tester.pump();
      expect(leftTaps, 1);
      expect(rightTaps, 0);
    });
  });
}

SlidingPane _pane(String name, {Widget? child}) {
  return SlidingPane(
    key: ValueKey<String>(name),
    title: signal(name),
    child: child ?? const ColoredBox(color: Colors.grey),
  );
}

class _ViewportHarness extends StatelessWidget {
  const _ViewportHarness({required this.panes});

  final List<SlidingPane> panes;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 800,
          height: 600,
          child: SlidingPaneViewport(panes: panes, visibleCount: 2),
        ),
      ),
    );
  }
}
