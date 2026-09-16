import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/main.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router.dart';

/// 真实入口冒烟：`DemoApp`（含 DemoFrame）启动落在引导页，进入主页后出现 rail。
void main() {
  testWidgets('DemoApp boots into onboarding and enters home', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.pumpAndSettle();
    expect(appRouter.location.value, '/onboarding');
    await tester.tap(find.byKey(const Key('onboarding-home')));
    await tester.pumpAndSettle();
    expect(appRouter.location.value, '/mail');
    expect(find.byType(NavigationRail), findsOneWidget);
  });
}
