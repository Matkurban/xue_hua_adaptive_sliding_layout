import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/size_preset_screen.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_pages.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/app_setting_services.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/theme/app_theme.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        return MaterialApp.router(
          title: 'Adaptive Sliding Layout',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: AppSettingServices.instance.themeMode.value,
          routerConfig: RouterPages.router,
          builder: (context, child) {
            return SizePresetScreen(
              context: context,
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
