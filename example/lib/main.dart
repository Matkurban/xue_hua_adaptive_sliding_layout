import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/features/settings/settings_pages.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/frame/demo_frame.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router.dart';

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
          theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: demoThemeMode.value,
          routerConfig: appRouter,
          builder: (context, child) {
            return DemoFrame(child: child ?? const SizedBox.shrink());
          },
        );
      },
    );
  }
}
