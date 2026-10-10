import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

/// 每个页面条目只能用自己的 arguments：任何重建（布局、分支切换、URL 同步）都不能拿到
/// 别的页面的参数或 null。
void main() {
  late Map<String, List<Object?>> built;

  AdaptiveRoute page(
    String path,
    String name, {
    List<AdaptiveRoute> routes = const [],
  }) {
    return AdaptiveRoute(
      path: path,
      hidesBottomBarWhenPushed: true,
      builder: (_, state) {
        built.putIfAbsent(name, () => []).add(state.arguments);
        return Scaffold(body: Text(name));
      },
      routes: routes,
    );
  }

  AdaptiveRouter buildRouter() => AdaptiveRouter(
    initialLocation: '/c',
    routes: [
      AdaptiveShellRoute(
        builder: (context, shell, child) => child,
        branches: [
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: '/a',
                builder: (_, _) => const Text('a'),
                routes: [page('select', 'a-select')],
              ),
            ],
          ),
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: '/c',
                builder: (_, _) => const Text('c'),
                routes: [
                  page('chat/:id', 'chat', routes: [page('sel', 'sel')]),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  setUp(() => built = {});

  Future<AdaptiveRouter> pumpRouter(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    final router = buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> pushChatAndSelect(
    WidgetTester tester,
    AdaptiveRouter router,
  ) async {
    router.pushNamed('/c/chat/1', arguments: 'chat-args');
    await tester.pumpAndSettle();
    router.pushNamed('/c/chat/1/sel', arguments: 42);
    await tester.pumpAndSettle();
  }

  Future<void> relayout(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 800);
    await tester.pumpAndSettle();
  }

  testWidgets('从聊天页推入选择页后，LayoutBuilder 重建仍用各自参数', (tester) async {
    final router = await pumpRouter(tester);
    await pushChatAndSelect(tester, router);
    built.clear();
    await relayout(tester, 420);
    await relayout(tester, 380);
    expect(built['sel'], isNotEmpty);
    expect(built['sel']!.every((a) => a == 42), isTrue);
    expect((built['chat'] ?? const []).every((a) => a == 'chat-args'), isTrue);
  });

  testWidgets('pop 之后重建，聊天页参数不变', (tester) async {
    final router = await pumpRouter(tester);
    await pushChatAndSelect(tester, router);
    router.pop();
    await tester.pumpAndSettle();
    built.clear();
    await relayout(tester, 420);
    expect(built['chat'], isNotEmpty);
    expect(built['chat']!.every((a) => a == 'chat-args'), isTrue);
  });

  testWidgets('切换分支再回来，各页参数不变', (tester) async {
    final router = await pumpRouter(tester);
    await pushChatAndSelect(tester, router);
    router.goBranch(0);
    await tester.pumpAndSettle();
    router.pushNamed('/a/select', arguments: 7);
    await tester.pumpAndSettle();
    built.clear();
    router.goBranch(1);
    await tester.pumpAndSettle();
    await relayout(tester, 420);
    expect(built['sel']!.every((a) => a == 42), isTrue);
    router.goBranch(0);
    await tester.pumpAndSettle();
    expect(built['a-select']!.every((a) => a == 7), isTrue);
  });

  testWidgets('跨分支推入深层页：中间页不拿叶子的参数，已知位置补回自己的参数', (tester) async {
    final router = await pumpRouter(tester);
    await pushChatAndSelect(tester, router);
    router.goBranch(0);
    await tester.pumpAndSettle();
    built.clear();
    router.pushNamed('/c/chat/1/sel', arguments: 99);
    await tester.pumpAndSettle();
    await relayout(tester, 420);
    expect(built['sel']!.last, 99);
    expect((built['chat'] ?? const []).every((a) => a == 'chat-args'), isTrue);
  });

  testWidgets('跨分支推入从未打开过的深层页：中间页参数为 null 而不是叶子的参数', (tester) async {
    final router = await pumpRouter(tester);
    router.goBranch(0);
    await tester.pumpAndSettle();
    router.pushNamed('/c/chat/9/sel', arguments: 5);
    await tester.pumpAndSettle();
    expect(
      router.matches.value.matches
          .firstWhere((m) => m.matchedLocation == '/c/chat/9')
          .arguments,
      isNull,
    );
    expect(router.matches.value.last!.arguments, 5);
  });

  testWidgets('URL 同步（系统 / 浏览器路由）回到已在栈上的页面时保留它的参数', (tester) async {
    final router = await pumpRouter(tester);
    await pushChatAndSelect(tester, router);
    final context = tester.element(find.text('sel'));
    final parsed = await router.routeInformationParser
        .parseRouteInformationWithDependencies(
          RouteInformation(uri: Uri.parse('/c/chat/1')),
          context,
        );
    built.clear();
    await router.routerDelegate.setNewRoutePath(parsed);
    await tester.pumpAndSettle();
    await relayout(tester, 420);
    expect(built['chat'], isNotEmpty);
    expect(built['chat']!.every((a) => a == 'chat-args'), isTrue);
  });
}
