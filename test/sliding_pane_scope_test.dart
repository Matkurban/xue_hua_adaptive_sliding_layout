import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SlidingPaneScope.showBackFor', () {
    test('root depth 1 never shows back', () {
      expect(SlidingPaneScope.showBackFor(index: 0, depth: 1), isFalse);
      expect(SlidingPaneScope.isStackTopFor(index: 0, depth: 1), isTrue);
    });

    test('depth 2 only stack top shows back', () {
      expect(SlidingPaneScope.showBackFor(index: 0, depth: 2), isFalse);
      expect(SlidingPaneScope.showBackFor(index: 1, depth: 2), isTrue);
    });

    test('depth 3 former stack top (left pane) does not show back', () {
      expect(SlidingPaneScope.showBackFor(index: 0, depth: 3), isFalse);
      expect(SlidingPaneScope.showBackFor(index: 1, depth: 3), isFalse);
      expect(SlidingPaneScope.showBackFor(index: 2, depth: 3), isTrue);
    });
  });

  group('SlidingBackButton', () {
    testWidgets('hides when not stack top', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SlidingPaneScope(
            index: 0,
            depth: 2,
            child: Scaffold(body: SlidingBackButton()),
          ),
        ),
      );
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('shows on stack top when depth > 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SlidingPaneScope(
            index: 1,
            depth: 2,
            child: Scaffold(body: SlidingBackButton()),
          ),
        ),
      );
      expect(find.byType(BackButton), findsOneWidget);
    });
  });

  group('SlidingWindowViewport pane showBack', () {
    late SlidingWindowController controller;

    setUp(() {
      controller = SlidingWindowController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('depth 2 only stack top reports showBack', (tester) async {
      controller.ensureRoot(
        name: 'Root',
        builder: (_) => const _ShowBackProbe(id: 'root'),
      );
      controller.push((_) => const _ShowBackProbe(id: 'a'), name: 'A');

      await tester.pumpWidget(_ViewportHarness(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('root:0'), findsOneWidget);
      expect(find.text('a:1'), findsOneWidget);
    });

    testWidgets('depth 3 left pane (former top) reports showBack false', (
      tester,
    ) async {
      controller.ensureRoot(
        name: 'Root',
        builder: (_) => const _ShowBackProbe(id: 'root'),
      );
      controller.push((_) => const _ShowBackProbe(id: 'a'), name: 'A');
      controller.push((_) => const _ShowBackProbe(id: 'b'), name: 'B');

      await tester.pumpWidget(_ViewportHarness(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('a:0'), findsOneWidget);
      expect(find.text('b:1'), findsOneWidget);
    });

    testWidgets('depth 2 default AppBar back only on stack top', (
      tester,
    ) async {
      controller.ensureRoot(
        name: 'Root',
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Root')),
          body: const SizedBox(),
        ),
      );
      controller.push(
        (_) => Scaffold(
          appBar: AppBar(title: const Text('Top')),
          body: const SizedBox(),
        ),
        name: 'Top',
      );

      await tester.pumpWidget(_ViewportHarness(controller: controller));
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(AppBar, 'Root'),
          matching: find.byType(BackButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(AppBar, 'Top'),
          matching: find.byType(BackButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('depth 3 default AppBar back moves to new stack top', (
      tester,
    ) async {
      controller.ensureRoot(
        name: 'Root',
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Root')),
          body: const SizedBox(),
        ),
      );
      controller.push(
        (_) => Scaffold(
          appBar: AppBar(title: const Text('A')),
          body: const SizedBox(),
        ),
        name: 'A',
      );

      await tester.pumpWidget(_ViewportHarness(controller: controller));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.widgetWithText(AppBar, 'A'),
          matching: find.byType(BackButton),
        ),
        findsOneWidget,
      );

      controller.push(
        (_) => Scaffold(
          appBar: AppBar(title: const Text('B')),
          body: const SizedBox(),
        ),
        name: 'B',
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.widgetWithText(AppBar, 'A'),
          matching: find.byType(BackButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(AppBar, 'B'),
          matching: find.byType(BackButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('pop restores default AppBar back on the new stack top', (
      tester,
    ) async {
      controller.ensureRoot(
        name: 'Root',
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Root')),
          body: const SizedBox(),
        ),
      );
      controller.push(
        (_) => Scaffold(
          appBar: AppBar(title: const Text('A')),
          body: const SizedBox(),
        ),
        name: 'A',
      );
      controller.push(
        (_) => Scaffold(
          appBar: AppBar(title: const Text('B')),
          body: const SizedBox(),
        ),
        name: 'B',
      );

      await tester.pumpWidget(_ViewportHarness(controller: controller));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.widgetWithText(AppBar, 'B'),
          matching: find.byType(BackButton),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(AppBar, 'A'),
          matching: find.byType(BackButton),
        ),
        findsNothing,
      );

      controller.pop();
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'B'), findsNothing);
      expect(
        find.descendant(
          of: find.widgetWithText(AppBar, 'A'),
          matching: find.byType(BackButton),
        ),
        findsOneWidget,
      );

      controller.pop();
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsNothing);
      expect(
        find.descendant(
          of: find.widgetWithText(AppBar, 'Root'),
          matching: find.byType(BackButton),
        ),
        findsNothing,
      );
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

class _ShowBackProbe extends StatelessWidget {
  const _ShowBackProbe({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final showBack = SlidingPaneScope.maybeOf(context)?.showBack ?? false;
    return Text('$id:${showBack ? '1' : '0'}');
  }
}
