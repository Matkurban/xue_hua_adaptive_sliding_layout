import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

class _RecordingFallback implements AdaptiveNavigatorFallback {
  int pushCount = 0;
  int pushNamedCount = 0;
  int pushReplacementCount = 0;
  int pushReplacementNamedCount = 0;
  int pushAndRemoveUntilCount = 0;
  int pushNamedAndRemoveUntilCount = 0;
  int popCount = 0;
  int popToRootCount = 0;

  @override
  Future<T?> push<T extends Object?>(Widget page, {BuildContext? from}) {
    pushCount++;
    return Future<T?>.value();
  }

  @override
  Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    pushNamedCount++;
    return Future<T?>.value();
  }

  @override
  Future<T?> pushReplacement<T extends Object?>(Widget page, {BuildContext? from}) {
    pushReplacementCount++;
    return Future<T?>.value();
  }

  @override
  Future<T?> pushReplacementNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
    String? fragment,
  }) {
    pushReplacementNamedCount++;
    return Future<T?>.value();
  }

  @override
  Future<T?> pushAndRemoveUntil<T extends Object?>(
    Widget page,
    bool Function(SlidingWindowPage page) predicate, {
    BuildContext? from,
  }) {
    pushAndRemoveUntilCount++;
    return Future<T?>.value();
  }

  @override
  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String name,
    bool Function(SlidingWindowPage page) predicate, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    pushNamedAndRemoveUntilCount++;
    return Future<T?>.value();
  }

  @override
  void pop<T extends Object?>([T? result]) {
    popCount++;
  }

  @override
  bool canPop() => false;

  @override
  bool popToRoot() {
    popToRootCount++;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SlidingWindowController stack;
  late _RecordingFallback fallback;
  late AdaptiveNavigator navigator;

  AdaptiveNavigator buildNav({bool sliding = true}) {
    return AdaptiveNavigator(
      isSlidingActive: () => sliding,
      currentStack: () => stack,
      buildPage: (args) => SizedBox(key: ValueKey<String>(args.name)),
      handlesRoute: (_) => true,
      fallback: fallback,
    );
  }

  setUp(() {
    stack = SlidingWindowController();
    stack.ensureRoot(name: 'Home', builder: (_) => const SizedBox());
    fallback = _RecordingFallback();
    navigator = buildNav();
  });

  tearDown(() {
    stack.dispose();
  });

  group('AdaptiveNavigator.popToRoot', () {
    test('depth 3 returns to root', () {
      stack.push((_) => const SizedBox(), name: 'A');
      stack.push((_) => const SizedBox(), name: 'B');
      expect(stack.depth, 3);

      expect(navigator.popToRoot(), isTrue);
      expect(stack.depth, 1);
      expect(stack.canPop, isFalse);
      expect(fallback.popToRootCount, 0);
    });

    test('returns false when already at root', () {
      expect(navigator.popToRoot(), isFalse);
      expect(stack.depth, 1);
    });

    test('falls back when sliding is inactive', () {
      navigator = buildNav(sliding: false);
      stack.push((_) => const SizedBox(), name: 'A');
      expect(navigator.popToRoot(), isTrue);
      expect(stack.depth, 2);
      expect(fallback.popToRootCount, 1);
    });
  });

  group('AdaptiveNavigator auto split', () {
    Future<BuildContext> pumpPane(
      WidgetTester tester, {
      required int index,
      required int depth,
    }) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SlidingPaneScope(
            index: index,
            depth: depth,
            child: const SizedBox(key: Key('pane')),
          ),
        ),
      );
      return tester.element(find.byKey(const Key('pane')));
    }

    testWidgets('root push is openAfter: [Home, B] not [A, B]', (tester) async {
      stack.push((_) => const SizedBox(), name: 'A');

      final context = await pumpPane(tester, index: 0, depth: 2);
      navigator.push(const SizedBox(), from: context, name: 'B');

      expect(stack.depth, 2);
      expect(stack.pages.value.map((page) => page.name), ['Home', 'B']);
      expect(fallback.pushCount, 0);
    });

    testWidgets('secondary push is Push Slide', (tester) async {
      stack.push((_) => const SizedBox(), name: 'A');

      final context = await pumpPane(tester, index: 1, depth: 2);
      navigator.push(const SizedBox(), from: context, name: 'C');

      expect(stack.depth, 3);
      expect(stack.visiblePages(2).map((page) => page.name), ['A', 'C']);
    });

    testWidgets('left pane same name replaces right pane not stack', (tester) async {
      stack.push((_) => const SizedBox(), name: 'A');
      stack.push((_) => const SizedBox(), name: 'B');

      final context = await pumpPane(tester, index: 1, depth: 3);
      navigator.push(const SizedBox(), from: context, name: 'B');

      expect(stack.depth, 3);
      expect(stack.pages.value.map((page) => page.name), ['Home', 'A', 'B']);
    });

    testWidgets('left pane new name replaces right pane', (tester) async {
      stack.push((_) => const SizedBox(), name: 'A');
      stack.push((_) => const SizedBox(), name: 'B');

      final context = await pumpPane(tester, index: 1, depth: 3);
      navigator.push(const SizedBox(), from: context, name: 'D');

      expect(stack.depth, 3);
      expect(stack.pages.value.map((page) => page.name), ['Home', 'A', 'D']);
    });

    testWidgets('push without pane at depth 3 stacks to depth 4', (tester) async {
      stack.push((_) => const SizedBox(), name: 'A');
      stack.push((_) => const SizedBox(), name: 'B');

      navigator.push(const SizedBox(), name: 'C');

      expect(stack.depth, 4);
      expect(stack.pages.value.map((page) => page.name), ['Home', 'A', 'B', 'C']);
    });

    test('pushAndRemoveUntil untilRoot replaces peer at depth 2', () {
      stack.push((_) => const SizedBox(), name: 'ChatA');
      navigator.pushAndRemoveUntil(const SizedBox(), AdaptiveNavigator.untilRoot, name: 'ChatB');

      expect(stack.depth, 2);
      expect(stack.pages.value.map((page) => page.name), ['Home', 'ChatB']);
    });

    test('falls back to pushNamed when sliding inactive', () {
      navigator = buildNav(sliding: false);
      navigator.pushNamed('/detail');
      expect(fallback.pushNamedCount, 1);
      expect(stack.depth, 1);
    });
  });
}
