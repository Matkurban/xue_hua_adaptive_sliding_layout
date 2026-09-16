import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('showBack is true only on the stack-top non-root pane', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdaptivePaneScope(
          index: 1,
          depth: 2,
          title: signal('A'),
          pop: () {},
          child: Builder(
            builder: (context) {
              final scope = AdaptivePaneScope.of(context);
              return Text('back-${scope.showBack}-top-${scope.isTop}');
            },
          ),
        ),
      ),
    );
    expect(find.text('back-true-top-true'), findsOneWidget);
  });

  testWidgets('root pane does not show back', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdaptivePaneScope(
          index: 0,
          depth: 1,
          title: signal('Root'),
          pop: () {},
          child: Builder(
            builder: (context) {
              return Text('${AdaptivePaneScope.of(context).showBack}');
            },
          ),
        ),
      ),
    );
    expect(find.text('false'), findsOneWidget);
  });
}
