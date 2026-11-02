import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

/// 每种预设页面过渡效果的展示元数据。
class TransitionPresetMeta {
  const TransitionPresetMeta({
    required this.type,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.factoryCode,
  });

  final AdaptivePageTransitionType type;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final String factoryCode;
}

/// 全部 18 种内置页面过渡效果的元数据列表。
const List<TransitionPresetMeta> transitionPresets = <TransitionPresetMeta>[
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.platform,
    title: '平台默认 (Platform)',
    category: '基础与平台',
    description: '跟随当前平台与 ThemeData.pageTransitionsTheme 的默认 Material 过渡。',
    icon: Icons.phone_iphone_outlined,
    factoryCode: 'AdaptivePageTransitions.builderFor(AdaptivePageTransitionType.platform)',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.none,
    title: '无动画瞬时 (None)',
    category: '基础与平台',
    description: '0ms 瞬时切换页面，无入场与退场动画，适合桌面端快速跳转。',
    icon: Icons.bolt_outlined,
    factoryCode: 'AdaptivePageTransitions.none',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.fade,
    title: '经典淡入淡出 (Fade)',
    category: '基础与平台',
    description: '平滑的透明度交叉渐变（0.0 → 1.0），适用于柔和的上下文切换。',
    icon: Icons.blur_on_outlined,
    factoryCode: 'AdaptivePageTransitions.fade()',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.fadeThrough,
    title: '穿透渐变 (Material 3 Fade Through)',
    category: '基础与平台',
    description: '旧页在前 35% 时段淡出并微缩，新页在后 65% 时段从 0.92 放大至 1.0 并淡入。',
    icon: Icons.layers_outlined,
    factoryCode: 'AdaptivePageTransitions.fadeThrough(initialScale: 0.92)',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.cupertino,
    title: 'iOS 视差右滑 (Cupertino)',
    category: '基础与平台',
    description: 'iOS / macOS 原生右滑进入，底层页面伴随 -1/3 宽度视差左移。',
    icon: Icons.swipe_left_outlined,
    factoryCode: 'AdaptivePageTransitions.cupertino()',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.slideRightToLeft,
    title: '从右侧滑入 (Slide Right → Left)',
    category: '方向滑动',
    description: '新页从屏幕右侧滑入，底层页面同步产生 -25% 视差左移。',
    icon: Icons.arrow_back_outlined,
    factoryCode: 'AdaptivePageTransitions.slideRightToLeft(parallax: true)',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.slideLeftToRight,
    title: '从左侧滑入 (Slide Left → Right)',
    category: '方向滑动',
    description: '新页从屏幕左侧滑入，底层页面同步产生 +25% 视差右移。',
    icon: Icons.arrow_forward_outlined,
    factoryCode: 'AdaptivePageTransitions.slideLeftToRight(parallax: true)',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.slideBottomToTop,
    title: '从底部上滑 (Slide Bottom → Top)',
    category: '方向滑动',
    description: '新页从屏幕底部向上滑入，适合模态详情、选择器或表单页。',
    icon: Icons.arrow_upward_outlined,
    factoryCode: 'AdaptivePageTransitions.slideBottomToTop()',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.slideTopToBottom,
    title: '从顶部下滑 (Slide Top → Bottom)',
    category: '方向滑动',
    description: '新页从屏幕顶部向下滑入，适合下拉通知栏或顶部抽屉面板。',
    icon: Icons.arrow_downward_outlined,
    factoryCode: 'AdaptivePageTransitions.slideTopToBottom()',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.sharedAxisHorizontal,
    title: '水平共享轴 (Shared Axis X)',
    category: 'Material 共享轴',
    description: 'Material 水平共享轴：新页从右侧偏移淡入，旧页向左侧偏移淡出。',
    icon: Icons.swap_horiz_outlined,
    factoryCode: 'AdaptivePageTransitions.sharedAxisHorizontal(offset: 30)',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.sharedAxisVertical,
    title: '垂直共享轴 (Shared Axis Y)',
    category: 'Material 共享轴',
    description: 'Material 垂直共享轴：新页从下方偏移淡入，旧页向上方偏移淡出。',
    icon: Icons.swap_vert_outlined,
    factoryCode: 'AdaptivePageTransitions.sharedAxisVertical(offset: 30)',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.sharedAxisScale,
    title: '深度共享轴 (Shared Axis Z)',
    category: 'Material 共享轴',
    description: 'Material 深度共享轴：新页从 0.8 放大至 1.0 淡入，旧页放大至 1.1 淡出。',
    icon: Icons.zoom_out_map_outlined,
    factoryCode: 'AdaptivePageTransitions.sharedAxisScale(beginScale: 0.8, exitScale: 1.1)',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.scale,
    title: '弹性中心缩放 (Scale)',
    category: '缩放 / 旋转 / 展开',
    description: '以中心（或自定义锚点）从 0.0 结合 easeOutBack 弹性曲线放大弹出。',
    icon: Icons.open_in_full_outlined,
    factoryCode: 'AdaptivePageTransitions.scale(alignment: Alignment.center)',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.fadeAndScale,
    title: '柔和渐变缩放 (Fade & Scale)',
    category: '缩放 / 旋转 / 展开',
    description: '从 0.85 倍平滑放大至 1.0 倍并伴随透明度淡入，适合弹窗式页面。',
    icon: Icons.filter_center_focus_outlined,
    factoryCode: 'AdaptivePageTransitions.fadeAndScale(beginScale: 0.85)',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.rotation,
    title: '旋转缩放淡入 (Rotation)',
    category: '缩放 / 旋转 / 展开',
    description: '结合旋转（0.85 → 1.0 圈）、缩放（0.6 → 1.0）与透明度淡入的复合效果。',
    icon: Icons.rotate_right_outlined,
    factoryCode:
        'AdaptivePageTransitions.rotation(beginTurns: 0.85, beginScale: 0.6)',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.size,
    title: '尺寸裁剪展开 (Size Reveal)',
    category: '缩放 / 旋转 / 展开',
    description: '沿指定轴（默认垂直方向）从中心对齐裁剪展开并伴随淡入。',
    icon: Icons.unfold_more_outlined,
    factoryCode: 'AdaptivePageTransitions.size(axis: Axis.vertical, alignment: Alignment.center)',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.flipHorizontal,
    title: '3D 水平卡片翻转 (Flip Horizontal)',
    category: '3D 透视翻转',
    description: '绕 Y 轴进行 3D 透视翻转（-90° → 0°）并伴随透明度平滑过渡。',
    icon: Icons.flip_outlined,
    factoryCode: 'AdaptivePageTransitions.flipHorizontal(perspective: 0.001)',
  ),
  TransitionPresetMeta(
    type: AdaptivePageTransitionType.flipVertical,
    title: '3D 垂直卡片翻转 (Flip Vertical)',
    category: '3D 透视翻转',
    description: '绕 X 轴进行 3D 透视翻转（90° → 0°）并伴随透明度平滑过渡。',
    icon: Icons.flip_camera_android_outlined,
    factoryCode: 'AdaptivePageTransitions.flipVertical(perspective: 0.001)',
  ),
];

/// 根据枚举名查找对应的 [TransitionPresetMeta]。
TransitionPresetMeta findTransitionPresetMeta(String? name) {
  for (final item in transitionPresets) {
    if (item.type.name == name) return item;
  }
  return transitionPresets.first;
}
