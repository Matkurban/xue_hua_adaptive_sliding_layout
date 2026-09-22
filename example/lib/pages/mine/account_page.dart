import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/app_setting_services.dart';

/// 账号页。未登录时由路由 redirect 送到登录页。
class AccountPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => AdaptiveRouter.of(context).maybePop(),
        ),
        title: const Text('账号'),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () {
            AppSettingServices.instance.signedIn.value = false;
            AdaptiveRouter.of(context).refresh();
          },
          child: const Text('退出登录'),
        ),
      ),
    );
  }
}
