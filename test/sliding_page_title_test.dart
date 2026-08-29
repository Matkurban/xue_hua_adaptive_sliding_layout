import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SlidingPageTitle.humanize', () {
    test('falls back to last path segment', () {
      expect(
        SlidingPageTitle.humanize('/unknownRouteName'),
        'Unknown Route Name',
      );
    });

    test('strips Page suffix', () {
      expect(SlidingPageTitle.humanize('ConfirmSendPage'), 'Confirm Send');
    });

    test('leaves already readable names', () {
      expect(SlidingPageTitle.humanize('Home'), 'Home');
    });
  });

  group('breadcrumb title', () {
    late SlidingWindowController controller;

    setUp(() {
      controller = SlidingWindowController();
    });

    testWidgets('shows page title instead of route path', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 800,
              height: 600,
              child: MultiColumnScaffold(
                controller: controller,
                root: const SizedBox(),
                rootName: '首页',
                visibleCount: 2,
                showBreadcrumbs: true,
              ),
            ),
          ),
        ),
      );
      controller.push((_) => const SizedBox(), name: '/assets', title: '资产');
      await tester.pumpAndSettle();

      expect(find.text('/assets'), findsNothing);
      expect(find.text('首页'), findsOneWidget);
      expect(find.text('资产'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });

    testWidgets('updates when title signal changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 800,
              height: 600,
              child: MultiColumnScaffold(
                controller: controller,
                root: const SizedBox(),
                rootName: '首页',
                visibleCount: 2,
                showBreadcrumbs: true,
              ),
            ),
          ),
        ),
      );
      controller.push((_) => const SizedBox(), name: '/chat', title: 'Chat');
      await tester.pumpAndSettle();
      expect(find.text('Chat'), findsOneWidget);

      controller.pages.value.last.title.value = 'Alice';
      await tester.pump();
      expect(find.text('Chat'), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });

    testWidgets('AppBar title overwrites initial title on first frame', (
      tester,
    ) async {
      controller.ensureRoot(name: 'Home', builder: (_) => const SizedBox());
      controller.push(
        (_) => Scaffold(
          appBar: AppBar(title: const Text('资产')),
          body: const SizedBox(),
        ),
        name: '/assets',
        title: '/assets',
      );

      await tester.pumpWidget(
        MaterialApp(
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
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.pages.value.last.title.value, '资产');
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });

    testWidgets('report during SignalBuilder build does not throw', (
      tester,
    ) async {
      controller.ensureRoot(name: 'Home', builder: (_) => const SizedBox());
      controller.push(
        (_) => Scaffold(
          appBar: AppBar(
            title: SignalBuilder(
              builder: (context) {
                SlidingPageTitle.maybeOf(context)?.report('Alice');
                return const Text('Alice');
              },
            ),
          ),
          body: const SizedBox(),
        ),
        name: '/chat',
        title: 'Chat',
      );

      await tester.pumpWidget(
        MaterialApp(
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
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.pages.value.last.title.value, 'Alice');
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  });
}
