import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/app_setting_services.dart';

/// 关于页。以全屏对话框盖住壳，用来看 fullscreenDialog。
class AboutPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => AdaptiveRouter.of(context).maybePop(),
        ),
        title: const Text('关于'),
      ),
      body: Center(
        child: SignalBuilder(
          builder: (context) {
            final preset = AppSettingServices.instance.sizePreset.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('这是一个全屏对话框页面。', style: theme.textTheme.titleMedium),
                SizedBox(height: 12),
                Text('当前宽度预设：${preset.label}'),
              ],
            );
          },
        ),
      ),
    );
  }
}
