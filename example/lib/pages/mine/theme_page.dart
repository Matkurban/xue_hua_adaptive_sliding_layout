import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/app_setting_services.dart';

/// 切换浅色、深色或跟随系统。配色方案不变。
class ThemePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => AdaptiveRouter.of(context).maybePop(),
        ),
        title: const Text('主题'),
      ),
      body: Center(
        child: SignalBuilder(
          builder: (context) {
            return SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('跟随系统')),
                ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
                ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
              ],
              selected: {AppSettingServices.instance.themeMode.value},
              onSelectionChanged: (value) {
                if (value.isEmpty) return;
                AppSettingServices.instance.themeMode.value = value.first;
              },
            );
          },
        ),
      ),
    );
  }
}
