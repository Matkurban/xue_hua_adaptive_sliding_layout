import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_names.dart';

class LoginPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final AdaptiveRouter router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Login Page')),
      body: Center(
        child: Column(
          spacing: 12,
          mainAxisAlignment: .center,
          children: [
            FilledButton(
              onPressed: () {
                router.pushNamedAndRemoveUntil(RouterNames.home, (_) => false);
              },
              child: Text('登录'),
            ),
            TextButton(
              onPressed: () {
                router.pushReplacementNamed(RouterNames.register);
              },
              child: Text('还没有账号？去注册'),
            ),
          ],
        ),
      ),
    );
  }
}
