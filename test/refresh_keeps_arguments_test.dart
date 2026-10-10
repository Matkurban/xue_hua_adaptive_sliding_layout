import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

void main() {
  late List<Object?> chatArgs;
  late bool redirectToLogin;

  AdaptiveRouter buildRouter() => AdaptiveRouter(
    initialLocation: '/c',
    redirect: (context, state) => redirectToLogin && state.uri.path != '/login' ? '/login' : null,
    routes: [
      AdaptiveRoute(path: '/login', builder: (_, _) => const Text('login')),
      AdaptiveShellRoute(
        builder: (context, shell, child) => child,
        branches: [
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: '/c',
                builder: (_, _) => const Text('c'),
                routes: [
                  AdaptiveRoute(
                    path: 'chat/:id',
                    builder: (_, s) {
                      chatArgs.add(s.arguments);
                      return const Text('chat');
                    },
                    routes: [AdaptiveRoute(path: 'sel', builder: (_, _) => const Text('sel'))],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  setUp(() {
    chatArgs = [];
    redirectToLogin = false;
  });

  Future<AdaptiveRouter> pump(WidgetTester tester) async {
    final router = buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.pushNamed('/c/chat/1', arguments: 'chat-args');
    await tester.pumpAndSettle();
    router.pushNamed('/c/chat/1/sel', arguments: 42);
    await tester.pumpAndSettle();
    router.pop('result');
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('pop 后列表级 arguments 跟随新栈顶', (tester) async {
    final router = await pump(tester);
    expect(router.matches.value.arguments, 'chat-args');
  });

  testWidgets('refresh 未重定向时保留现有栈，中间页参数不被替换', (tester) async {
    final router = await pump(tester);
    chatArgs.clear();
    final before = router.matches.value;
    router.refresh();
    await tester.pumpAndSettle();
    expect(identical(router.matches.value, before), isTrue);
    expect(chatArgs.every((a) => a == 'chat-args'), isTrue);
    expect(find.text('chat'), findsOneWidget);
  });

  testWidgets('refresh 被重定向时仍然换栈', (tester) async {
    final router = await pump(tester);
    redirectToLogin = true;
    router.refresh();
    await tester.pumpAndSettle();
    expect(router.location.value, '/login');
    expect(find.text('login'), findsOneWidget);
  });
}
