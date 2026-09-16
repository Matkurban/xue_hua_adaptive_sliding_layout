import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/data/auth.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/features/contacts/contact_pages.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/features/mail/mail_pages.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/features/settings/settings_pages.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/frame/demo_frame.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router.dart';

/// 把示例路由器挂到 [MaterialApp.router]，不含 DemoFrame。
Widget exampleApp(AdaptiveRouter router) {
  return MaterialApp.router(routerConfig: router);
}

/// 固定测试窗口逻辑像素，避免 DPR 把 1200 宽缩成 compact。
Future<void> setSurfaceSize(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 示例里的全局 signal 会跨测试存活，每条用例开头清掉。
void resetExampleSignals() {
  signedIn.value = false;
  mailReplyDirty.value = false;
  contactEditDirty.value = false;
  demoThemeMode.value = ThemeMode.system;
  demoSizePreset.value = DemoSizePreset.desktop;
}

/// 泵入一条干净的示例路由树，返回路由器实例。
Future<AdaptiveRouter> pumpExample(
  WidgetTester tester, {
  double width = 1200,
}) async {
  resetExampleSignals();
  await setSurfaceSize(tester, width);
  final router = createAppRouter();
  await tester.pumpWidget(exampleApp(router));
  await tester.pumpAndSettle();
  return router;
}
