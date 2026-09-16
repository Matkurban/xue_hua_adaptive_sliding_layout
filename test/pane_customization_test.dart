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

  testWidgets('paneBuilder wraps panes and placeholder slot', (tester) async {
    final indexes = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 800,
            height: 600,
            child: SlidingPaneViewport(
              panes: [_pane('Root')],
              visibleCount: 2,
              paneBuilder: (context, index, child) {
                indexes.add(index);
                return ColoredBox(
                  color: Colors.orange,
                  child: KeyedSubtree(
                    key: Key('framed-$index'),
                    child: child,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(indexes, containsAll([0, 1]));
    expect(find.byKey(const Key('framed-0')), findsOneWidget);
    expect(find.byKey(const Key('framed-1')), findsOneWidget);
  });

  testWidgets('resizeHandleBuilder paints a custom handle that still drags', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 800,
            height: 600,
            child: SlidingPaneViewport(
              panes: [_pane('Root'), _pane('A')],
              visibleCount: 2,
              resizeHandleBuilder: (context) => const ColoredBox(
                color: Colors.red,
                child: Text('custom-handle'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('custom-handle'), findsOneWidget);
    await tester.drag(
      find.byKey(SlidingPaneViewport.resizeHandleKey),
      const Offset(80, 0),
      touchSlopX: 0,
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(SlidingPaneViewport.visibleLeftPaneKey)).width,
      480,
    );
  });

  testWidgets('slideDuration keeps the strip mid-flight', (tester) async {
    Widget viewport(List<SlidingPane> panes) {
      return MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 800,
            height: 600,
            child: SlidingPaneViewport(
              panes: panes,
              visibleCount: 2,
              slideDuration: const Duration(seconds: 1),
              slideCurve: Curves.linear,
            ),
          ),
        ),
      );
    }

    final root = _pane('Root');
    final a = _pane('A');
    await tester.pumpWidget(viewport([root, a]));
    await tester.pumpAndSettle();

    await tester.pumpWidget(viewport([root, a, _pane('B')]));
    await tester.pump(const Duration(milliseconds: 250));
    final transform = tester.widget<Transform>(find.byType(Transform).first);
    final dx = transform.transform.getTranslation().x;
    expect(dx, lessThan(0));
    expect(dx, greaterThan(-400));
    await tester.pumpAndSettle();
  });
}
