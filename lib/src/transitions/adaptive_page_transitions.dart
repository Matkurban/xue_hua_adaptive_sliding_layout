import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/transitions/adaptive_page_transition_type.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/transitions/builders/fade_scale_transitions.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/transitions/builders/flip_transitions.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/transitions/builders/shared_axis_transitions.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/transitions/builders/slide_transitions.dart';

/// 预置页面过渡动画工厂。
///
/// 可直接将本类的静态方法传给 [AdaptiveRoute.transitionsBuilder] 或
/// `AdaptiveRouter.defaultTransitionsBuilder`，也可直接使用枚举
/// [AdaptivePageTransitionType] 配置 [AdaptiveRoute.transitionType]。
abstract final class AdaptivePageTransitions {
  /// 无动画过渡：直接展示目标页面。
  static AdaptiveTransitionsBuilder get none => FadeScalePageTransitions.none;

  /// 经典透明度淡入淡出过渡。
  static AdaptiveTransitionsBuilder fade({
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) => FadeScalePageTransitions.fade(curve: curve, reverseCurve: reverseCurve);

  /// Material 3 穿透渐变（Fade Through）。
  static AdaptiveTransitionsBuilder fadeThrough({
    double initialScale = 0.92,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) => FadeScalePageTransitions.fadeThrough(
    initialScale: initialScale,
    curve: curve,
    reverseCurve: reverseCurve,
  );

  /// 从右侧滑入（带底层页面视差左移）。
  static AdaptiveTransitionsBuilder slideRightToLeft({
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
    bool parallax = true,
  }) => SlidePageTransitions.slideRightToLeft(
    curve: curve,
    reverseCurve: reverseCurve,
    parallax: parallax,
  );

  /// 从左侧滑入（带底层页面视差右移）。
  static AdaptiveTransitionsBuilder slideLeftToRight({
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
    bool parallax = true,
  }) => SlidePageTransitions.slideLeftToRight(
    curve: curve,
    reverseCurve: reverseCurve,
    parallax: parallax,
  );

  /// 从底部向上滑入。
  static AdaptiveTransitionsBuilder slideBottomToTop({
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) => SlidePageTransitions.slideBottomToTop(
    curve: curve,
    reverseCurve: reverseCurve,
  );

  /// 从顶部向下滑入。
  static AdaptiveTransitionsBuilder slideTopToBottom({
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) => SlidePageTransitions.slideTopToBottom(
    curve: curve,
    reverseCurve: reverseCurve,
  );

  /// iOS / macOS 风格 Cupertino 原生右滑视差过渡。
  static AdaptiveTransitionsBuilder cupertino({
    bool linearTransition = false,
    Curve curve = Curves.linearToEaseOut,
    Curve? reverseCurve,
  }) => SlidePageTransitions.cupertino(
    linearTransition: linearTransition,
    curve: curve,
    reverseCurve: reverseCurve,
  );

  /// 缩放弹出过渡。
  static AdaptiveTransitionsBuilder scale({
    Alignment alignment = Alignment.center,
    double beginScale = 0.0,
    Curve curve = Curves.easeOutBack,
    Curve? reverseCurve,
  }) => FadeScalePageTransitions.scale(
    alignment: alignment,
    beginScale: beginScale,
    curve: curve,
    reverseCurve: reverseCurve,
  );

  /// 透明度渐变伴随柔和缩放过渡（默认从 0.85 缩放至 1.0）。
  static AdaptiveTransitionsBuilder fadeAndScale({
    Alignment alignment = Alignment.center,
    double beginScale = 0.85,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) => FadeScalePageTransitions.fadeAndScale(
    alignment: alignment,
    beginScale: beginScale,
    curve: curve,
    reverseCurve: reverseCurve,
  );

  /// Material 水平共享轴（Shared Axis X）过渡。
  static AdaptiveTransitionsBuilder sharedAxisHorizontal({
    double offset = 30.0,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) => SharedAxisPageTransitions.horizontal(
    offset: offset,
    curve: curve,
    reverseCurve: reverseCurve,
  );

  /// Material 垂直共享轴（Shared Axis Y）过渡。
  static AdaptiveTransitionsBuilder sharedAxisVertical({
    double offset = 30.0,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) => SharedAxisPageTransitions.vertical(
    offset: offset,
    curve: curve,
    reverseCurve: reverseCurve,
  );

  /// Material 深度共享轴（Shared Axis Z / Scale）过渡。
  static AdaptiveTransitionsBuilder sharedAxisScale({
    double beginScale = 0.8,
    double exitScale = 1.1,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) => SharedAxisPageTransitions.scale(
    beginScale: beginScale,
    exitScale: exitScale,
    curve: curve,
    reverseCurve: reverseCurve,
  );

  /// 旋转伴随缩放与淡入过渡。
  static AdaptiveTransitionsBuilder rotation({
    double beginTurns = 0.85,
    double beginScale = 0.6,
    Alignment alignment = Alignment.center,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) => FadeScalePageTransitions.rotation(
    beginTurns: beginTurns,
    beginScale: beginScale,
    alignment: alignment,
    curve: curve,
    reverseCurve: reverseCurve,
  );

  /// 尺寸裁剪展开伴随淡入过渡。
  static AdaptiveTransitionsBuilder size({
    Axis axis = Axis.vertical,
    AlignmentGeometry alignment = Alignment.center,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) => FadeScalePageTransitions.size(
    axis: axis,
    alignment: alignment,
    curve: curve,
    reverseCurve: reverseCurve,
  );

  /// 3D 水平卡片翻转（绕 Y 轴）过渡。
  static AdaptiveTransitionsBuilder flipHorizontal({
    double perspective = 0.001,
    Curve curve = Curves.easeInOutCubic,
    Curve? reverseCurve,
  }) => FlipPageTransitions.horizontal(
    perspective: perspective,
    curve: curve,
    reverseCurve: reverseCurve,
  );

  /// 3D 垂直卡片翻转（绕 X 轴）过渡。
  static AdaptiveTransitionsBuilder flipVertical({
    double perspective = 0.001,
    Curve curve = Curves.easeInOutCubic,
    Curve? reverseCurve,
  }) => FlipPageTransitions.vertical(
    perspective: perspective,
    curve: curve,
    reverseCurve: reverseCurve,
  );

  /// 根据 [AdaptivePageTransitionType] 枚举返回对应的过渡构建器；
  /// [AdaptivePageTransitionType.platform] 返回 null。
  static AdaptiveTransitionsBuilder? builderFor(
    AdaptivePageTransitionType type, {
    Curve? curve,
    Curve? reverseCurve,
  }) {
    final effectiveCurve = curve ?? Curves.easeOutCubic;
    return switch (type) {
      AdaptivePageTransitionType.platform => null,
      AdaptivePageTransitionType.none => none,
      AdaptivePageTransitionType.fade => fade(
        curve: effectiveCurve,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.fadeThrough => fadeThrough(
        curve: effectiveCurve,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.slideRightToLeft => slideRightToLeft(
        curve: effectiveCurve,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.slideLeftToRight => slideLeftToRight(
        curve: effectiveCurve,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.slideBottomToTop => slideBottomToTop(
        curve: effectiveCurve,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.slideTopToBottom => slideTopToBottom(
        curve: effectiveCurve,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.cupertino => cupertino(
        curve: curve ?? Curves.linearToEaseOut,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.scale => scale(
        curve: curve ?? Curves.easeOutBack,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.fadeAndScale => fadeAndScale(
        curve: effectiveCurve,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.sharedAxisHorizontal => sharedAxisHorizontal(
        curve: effectiveCurve,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.sharedAxisVertical => sharedAxisVertical(
        curve: effectiveCurve,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.sharedAxisScale => sharedAxisScale(
        curve: effectiveCurve,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.rotation => rotation(
        curve: effectiveCurve,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.size => size(
        curve: effectiveCurve,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.flipHorizontal => flipHorizontal(
        curve: curve ?? Curves.easeInOutCubic,
        reverseCurve: reverseCurve,
      ),
      AdaptivePageTransitionType.flipVertical => flipVertical(
        curve: curve ?? Curves.easeInOutCubic,
        reverseCurve: reverseCurve,
      ),
    };
  }
}
