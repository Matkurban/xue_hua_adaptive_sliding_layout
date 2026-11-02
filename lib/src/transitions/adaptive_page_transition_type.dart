import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/transitions/adaptive_page_transitions.dart';

/// 预置的页面过渡动画类型（共 18 种常用效果）。
///
/// 可在单个 [AdaptiveRoute.transitionType] 上按路由配置，也可在
/// `AdaptiveRouter.defaultTransitionType` 上配置全局默认过渡效果。
enum AdaptivePageTransitionType {
  /// 跟随当前平台与 `ThemeData.pageTransitionsTheme` 的默认 Material 过渡。
  platform,

  /// 无动画，页面立即切换（耗时为 0）。
  none,

  /// 经典透明度渐变（Fade）。
  fade,

  /// Material 3 穿透渐变（Fade Through：旧页先淡出，新页微缩放伴随淡入）。
  fadeThrough,

  /// 从右侧滑入（Push 时自右向左，带底层页面视差左移）。
  slideRightToLeft,

  /// 从左侧滑入（Push 时自左向右，带底层页面视差右移）。
  slideLeftToRight,

  /// 从底部向上滑入（适用于模态页、详情弹层）。
  slideBottomToTop,

  /// 从顶部向下滑入（适用于通知抽屉、顶部面板）。
  slideTopToBottom,

  /// iOS / macOS 风格 Cupertino 原生右滑视差过渡。
  cupertino,

  /// 中心缩放弹出（Scale）。
  scale,

  /// 透明度渐变伴随柔和缩放（Fade + Scale）。
  fadeAndScale,

  /// Material 水平共享轴过渡（Shared Axis X：水平位移 + 渐隐渐显）。
  sharedAxisHorizontal,

  /// Material 垂直共享轴过渡（Shared Axis Y：垂直位移 + 渐隐渐显）。
  sharedAxisVertical,

  /// Material 深度共享轴过渡（Shared Axis Z：前后层缩放 + 渐隐渐显）。
  sharedAxisScale,

  /// 旋转伴随缩放与淡入（Rotation + Scale + Fade）。
  rotation,

  /// 尺寸展开过渡（Size Reveal + Fade）。
  size,

  /// 3D 水平卡片翻转（绕 Y 轴透视翻转）。
  flipHorizontal,

  /// 3D 垂直卡片翻转（绕 X 轴透视翻转）。
  flipVertical;

  /// 该过渡类型的推荐默认时长。
  Duration get defaultDuration {
    return switch (this) {
      AdaptivePageTransitionType.none => Duration.zero,
      AdaptivePageTransitionType.flipHorizontal ||
      AdaptivePageTransitionType.flipVertical => const Duration(
        milliseconds: 400,
      ),
      _ => const Duration(milliseconds: 300),
    };
  }

  /// 生成该过渡类型对应的 [AdaptiveTransitionsBuilder]；
  /// [AdaptivePageTransitionType.platform] 返回 null（走默认 Material 路由）。
  AdaptiveTransitionsBuilder? builder({Curve? curve, Curve? reverseCurve}) {
    return AdaptivePageTransitions.builderFor(
      this,
      curve: curve,
      reverseCurve: reverseCurve,
    );
  }
}
