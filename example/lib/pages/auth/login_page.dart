import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_names.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/app_setting_services.dart';

class LoginPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final AdaptiveRouter router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => router.maybePop()),
        title: Text('Login Page'),
      ),
      body: Center(
        child: Column(
          spacing: 12,
          mainAxisAlignment: .center,
          children: [
            FilledButton(onPressed: () => _enter(context), child: Text('登录')),
            TextButton(
              onPressed: () => _swap(context, RouterNames.register),
              child: Text('还没有账号？去注册'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 登录成功后回到 [from]，没有则进入首页。
void _enter(BuildContext context) {
  AppSettingServices.instance.signedIn.value = true;
  final router = AdaptiveRouter.of(context);
  final from = AdaptiveRouteState.of(context).queryParameters['from'];
  router.pushNamedAndRemoveUntil(from ?? RouterNames.home, (_) => false);
}

/// 登录和注册对跳，保留原来的 from。
void _swap(BuildContext context, String path) {
  final router = AdaptiveRouter.of(context);
  final from = AdaptiveRouteState.of(context).queryParameters['from'];
  final location = from == null
      ? path
      : '$path?from=${Uri.encodeComponent(from)}';
  router.pushReplacementNamed(location);
}
