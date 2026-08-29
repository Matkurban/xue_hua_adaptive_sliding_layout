import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget page(String name) => SizedBox(key: ValueKey<String>(name));

  group('SlidingWindowController', () {
    late SlidingWindowController controller;

    setUp(() {
      controller = SlidingWindowController();
      controller.ensureRoot(name: 'Home', builder: (_) => page('Home'));
    });

    tearDown(() {
      controller.dispose();
    });

    test('root cannot pop and visiblePages of 2 is root only', () {
      expect(controller.depth, 1);
      expect(controller.canPop, isFalse);
      expect(controller.visiblePages(2).map((page) => page.name), ['Home']);
    });

    test('depth 2 shows Home and A', () {
      controller.push((_) => page('A'), name: 'A');
      expect(controller.visiblePages(2).map((page) => page.name), [
        'Home',
        'A',
      ]);
    });

    test('depth 3 shows A and B', () {
      controller.push((_) => page('A'), name: 'A');
      controller.push((_) => page('B'), name: 'B');
      expect(controller.depth, 3);
      expect(controller.visiblePages(2).map((page) => page.name), ['A', 'B']);
    });

    test('depth 4 shows B and C', () {
      controller.push((_) => page('A'), name: 'A');
      controller.push((_) => page('B'), name: 'B');
      controller.push((_) => page('C'), name: 'C');
      expect(controller.visiblePages(2).map((page) => page.name), ['B', 'C']);
      expect(controller.visiblePages(1).map((page) => page.name), ['C']);
    });

    test('pop completes the pushed future', () async {
      final future = controller.push<String>((_) => page('A'), name: 'A');
      expect(controller.pop('result'), isTrue);
      expect(await future, 'result');
      expect(controller.depth, 1);
    });

    test('popUntil stops at matching page', () {
      controller.push((_) => page('A'), name: 'A');
      controller.push((_) => page('B'), name: 'B');
      controller.push((_) => page('C'), name: 'C');
      controller.popUntil((page) => page.name == 'A');
      expect(controller.pages.value.map((page) => page.name), ['Home', 'A']);
    });

    test('replace swaps the top page', () async {
      controller.push((_) => page('A'), name: 'A');
      final future = controller.replace<String>((_) => page('B'), name: 'B');
      expect(controller.pages.value.map((page) => page.name), ['Home', 'B']);
      controller.pop('ok');
      expect(await future, 'ok');
    });

    test(
      'openAfter keepCount 2 at depth 3 with same name B stays Home A B',
      () {
        controller.push((_) => page('A'), name: 'A');
        controller.push((_) => page('B'), name: 'B');
        controller.openAfter(2, (_) => page('B2'), name: 'B');
        expect(controller.depth, 3);
        expect(controller.pages.value.map((page) => page.name), [
          'Home',
          'A',
          'B',
        ]);
      },
    );

    test('openAfter keepCount 2 at depth 3 with new name D is Home A D', () {
      controller.push((_) => page('A'), name: 'A');
      controller.push((_) => page('B'), name: 'B');
      controller.openAfter(2, (_) => page('D'), name: 'D');
      expect(controller.depth, 3);
      expect(controller.pages.value.map((page) => page.name), [
        'Home',
        'A',
        'D',
      ]);
    });

    test('indexOfName finds from the back', () {
      controller.push((_) => page('A'), name: 'A');
      controller.push((_) => page('B'), name: 'B');
      expect(controller.indexOfName('B'), 2);
      expect(controller.indexOfName('A'), 1);
      expect(controller.indexOfName('Home'), 0);
      expect(controller.indexOfName('missing'), -1);
      expect(controller.indexOfName(''), -1);
    });

    test('openSecondary from root becomes Home and A', () {
      controller.openSecondary((_) => page('A'), name: 'A');
      expect(controller.depth, 2);
      expect(controller.pages.value.map((page) => page.name), ['Home', 'A']);
      expect(controller.visiblePages(2).map((page) => page.name), [
        'Home',
        'A',
      ]);
    });

    test('openSecondary at depth 2 stays depth 2 with Home and B', () {
      controller.push((_) => page('A'), name: 'A');
      controller.openSecondary((_) => page('B'), name: 'B');
      expect(controller.depth, 2);
      expect(controller.pages.value.map((page) => page.name), ['Home', 'B']);
      expect(controller.visiblePages(2).map((page) => page.name), [
        'Home',
        'B',
      ]);
    });

    test(
      'openSecondary then push C is depth 3; pops return to Home B then root',
      () {
        controller.openSecondary((_) => page('B'), name: 'B');
        controller.push((_) => page('C'), name: 'C');
        expect(controller.depth, 3);
        expect(controller.visiblePages(2).map((page) => page.name), ['B', 'C']);

        expect(controller.pop(), isTrue);
        expect(controller.pages.value.map((page) => page.name), ['Home', 'B']);
        expect(controller.visiblePages(2).map((page) => page.name), [
          'Home',
          'B',
        ]);

        expect(controller.pop(), isTrue);
        expect(controller.depth, 1);
        expect(controller.pages.value.single.name, 'Home');
      },
    );

    test('popToRoot from depth 3 returns to root', () {
      controller.push((_) => page('A'), name: 'A');
      controller.push((_) => page('B'), name: 'B');
      expect(controller.depth, 3);
      controller.popToRoot();
      expect(controller.depth, 1);
      expect(controller.canPop, isFalse);
      expect(controller.pages.value.single.name, 'Home');
    });

    test('popToRoot at root is a no-op', () {
      controller.popToRoot();
      expect(controller.depth, 1);
      expect(controller.pages.value.single.name, 'Home');
    });

    test('push title defaults to name and can be overridden', () {
      controller.push((_) => page('A'), name: '/assets');
      expect(controller.pages.value.last.title.value, '/assets');
      controller.push((_) => page('B'), name: '/deposit', title: '汇入');
      expect(controller.pages.value.last.title.value, '汇入');
    });

    test('ensureRoot is ignored when stack is not empty', () {
      controller.ensureRoot(name: 'Other', builder: (_) => page('Other'));
      expect(controller.pages.value.single.name, 'Home');
    });
  });
}
