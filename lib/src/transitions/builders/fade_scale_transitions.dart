import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route.dart';

/// 渐变、缩放、旋转与尺寸展开类页面过渡构建器集合。
abstract final class FadeScalePageTransitions {
  /// 无动画过渡：直接返回 [child]。
  static Widget none(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }

  /// 经典透明度淡入淡出。
  static AdaptiveTransitionsBuilder fade({
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) {
    return (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: curve,
        reverseCurve: reverseCurve ?? curve.flipped,
      );
      return FadeTransition(opacity: curved, child: child);
    };
  }

  /// Material 3 穿透渐变（Fade Through）：
  /// 下层页面在前 35% 时段淡出，新页面在后 65% 时段从 [initialScale] 放大至 1.0 并淡入。
  static AdaptiveTransitionsBuilder fadeThrough({
    double initialScale = 0.92,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) {
    return (context, animation, secondaryAnimation, child) {
      final enterFade = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
        reverseCurve: const Interval(0.0, 0.65, curve: Curves.easeIn),
      );
      final enterScale = CurvedAnimation(
        parent: animation,
        curve: Interval(0.35, 1.0, curve: curve),
        reverseCurve: Interval(0.0, 0.65, curve: reverseCurve ?? curve.flipped),
      );
      final exitFade = CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
        reverseCurve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      );
      final exitScale = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Interval(0.0, 0.35, curve: curve),
        reverseCurve: Interval(0.65, 1.0, curve: reverseCurve ?? curve.flipped),
      );

      return FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(exitFade),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 1.0,
            end: initialScale,
          ).animate(exitScale),
          child: FadeTransition(
            opacity: enterFade,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: initialScale,
                end: 1.0,
              ).animate(enterScale),
              child: child,
            ),
          ),
        ),
      );
    };
  }

  /// 中心或指定锚点缩放过渡。
  static AdaptiveTransitionsBuilder scale({
    Alignment alignment = Alignment.center,
    double beginScale = 0.0,
    Curve curve = Curves.easeOutBack,
    Curve? reverseCurve,
  }) {
    return (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: curve,
        reverseCurve: reverseCurve ?? Curves.easeInCubic,
      );
      return ScaleTransition(
        alignment: alignment,
        scale: Tween<double>(begin: beginScale, end: 1.0).animate(curved),
        child: child,
      );
    };
  }

  /// 透明度渐变伴随柔和缩放（默认从 0.85 放大至 1.0）。
  static AdaptiveTransitionsBuilder fadeAndScale({
    Alignment alignment = Alignment.center,
    double beginScale = 0.85,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) {
    return (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: curve,
        reverseCurve: reverseCurve ?? curve.flipped,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          alignment: alignment,
          scale: Tween<double>(begin: beginScale, end: 1.0).animate(curved),
          child: child,
        ),
      );
    };
  }

  /// 旋转伴随缩放与淡入过渡。
  static AdaptiveTransitionsBuilder rotation({
    double beginTurns = 0.85,
    double beginScale = 0.6,
    Alignment alignment = Alignment.center,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) {
    return (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: curve,
        reverseCurve: reverseCurve ?? curve.flipped,
      );
      return FadeTransition(
        opacity: curved,
        child: RotationTransition(
          alignment: alignment,
          turns: Tween<double>(begin: beginTurns, end: 1.0).animate(curved),
          child: ScaleTransition(
            alignment: alignment,
            scale: Tween<double>(begin: beginScale, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    };
  }

  /// 沿指定轴尺寸裁剪展开伴随淡入过渡。
  static AdaptiveTransitionsBuilder size({
    Axis axis = Axis.vertical,
    AlignmentGeometry alignment = Alignment.center,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) {
    return (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: curve,
        reverseCurve: reverseCurve ?? curve.flipped,
      );
      return Align(
        alignment: Alignment.center,
        child: FadeTransition(
          opacity: curved,
          child: SizeTransition(
            axis: axis,
            alignment: alignment,
            sizeFactor: curved,
            child: child,
          ),
        ),
      );
    };
  }
}
