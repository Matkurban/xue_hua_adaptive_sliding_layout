import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/model/enums/size_preset.dart';

///软件全局设置
class AppSettingServices {
  AppSettingServices._();

  static final AppSettingServices instance = AppSettingServices._();

  /// 当前选中的宽度预设。
  final Signal<SizePreset> sizePreset = signal(SizePreset.desktop);

  /// 示例用的登录态。真实应用换成自己的 auth 服务。
  final Signal<bool> signedIn = signal(false);

  /// 浅色、深色或跟随系统。配色仍用现有的浅色和深色主题。
  final Signal<ThemeMode> themeMode = signal(ThemeMode.system);
}
