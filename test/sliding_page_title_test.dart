import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('humanizePath', () {
    test('falls back to last path segment', () {
      expect(humanizePath('/unknownRouteName'), 'Unknown Route Name');
    });

    test('strips Page suffix', () {
      expect(humanizePath('ConfirmSendPage'), 'Confirm Send');
    });

    test('leaves already readable names', () {
      expect(humanizePath('Home'), 'Home');
    });
  });

  group('AdaptiveBreadcrumbs', () {
    testWidgets('shows titles and pops to a tapped crumb', (tester) async {
      final root = SlidingPane(
        key: const ValueKey('root'),
        title: signal('首页'),
        child: const SizedBox(),
      );
      final assets = SlidingPane(
        key: const ValueKey('assets'),
        title: signal('资产'),
        child: const SizedBox(),
      );
      LocalKey? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveBreadcrumbs(
              panes: [root, assets],
              onSelect: (pane) => selected = pane.key,
            ),
          ),
        ),
      );
      expect(find.text('首页'), findsOneWidget);
      expect(find.text('资产'), findsOneWidget);
      await tester.tap(find.text('首页'));
      expect(selected, const ValueKey('root'));
    });

    testWidgets('updates when title signal changes', (tester) async {
      final title = signal('Inbox');
      final pane = SlidingPane(
        key: const ValueKey('inbox'),
        title: title,
        child: const SizedBox(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveBreadcrumbs(panes: [pane], onSelect: (_) {}),
          ),
        ),
      );
      expect(find.text('Inbox'), findsOneWidget);
      title.value = 'Alice';
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('itemBuilder, separatorBuilder and height apply', (tester) async {
      final root = SlidingPane(
        key: const ValueKey('root'),
        title: signal('Home'),
        child: const SizedBox(),
      );
      final next = SlidingPane(
        key: const ValueKey('next'),
        title: signal('Next'),
        child: const SizedBox(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveBreadcrumbs(
              panes: [root, next],
              onSelect: (_) {},
              height: 48,
              itemBuilder: (context, pane, isLast, onTap) {
                return Text('item-${pane.title.value}');
              },
              separatorBuilder: (context, index) => const Text('|'),
            ),
          ),
        ),
      );
      expect(find.text('item-Home'), findsOneWidget);
      expect(find.text('item-Next'), findsOneWidget);
      expect(find.text('|'), findsOneWidget);
      expect(tester.getSize(find.byType(AdaptiveBreadcrumbs)).height, 48);
    });
  });
}
