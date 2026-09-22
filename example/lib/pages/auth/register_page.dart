import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_names.dart';

class RegisterPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final AdaptiveRouter router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Register Page')),
      body: Center(
        child: Column(
          spacing: 12,
          mainAxisAlignment: .center,
          children: [
            FilledButton(
              onPressed: () {
                router.pushNamedAndRemoveUntil(RouterNames.home, (_) => false);
              },
              child: Text('注册'),
            ),
            TextButton(
              onPressed: () {
                router.pushReplacementNamed(RouterNames.login);
              },
              child: Text('已有账号？去登录'),
            ),
          ],
        ),
      ),
    );
  }
}
