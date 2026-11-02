import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route.dart';

/// Material Design 共享轴（Shared Axis X / Y / Z）页面过渡构建器集合。
abstract final class SharedAxisPageTransitions {
  /// 水平共享轴（Shared Axis X）：新页从右侧偏移 [offset] 像素淡入，旧页向左侧偏移淡出。
  static AdaptiveTransitionsBuilder horizontal({
    double offset = 30.0,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) {
    return _sharedAxisTranslation(
      beginOffset: Offset(offset, 0.0),
      exitOffset: Offset(-offset, 0.0),
      curve: curve,
      reverseCurve: reverseCurve,
    );
  }

  /// 垂直共享轴（Shared Axis Y）：新页从下方偏移 [offset] 像素淡入，旧页向上方偏移淡出。
  static AdaptiveTransitionsBuilder vertical({
    double offset = 30.0,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) {
    return _sharedAxisTranslation(
      beginOffset: Offset(0.0, offset),
      exitOffset: Offset(0.0, -offset),
      curve: curve,
      reverseCurve: reverseCurve,
    );
  }

  /// 深度共享轴（Shared Axis Z）：新页从 [beginScale] 放大至 1.0 并淡入，旧页放大至 [exitScale] 并淡出。
  static AdaptiveTransitionsBuilder scale({
    double beginScale = 0.8,
    double exitScale = 1.1,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) {
    return (context, animation, secondaryAnimation, child) {
      final primaryCurved = CurvedAnimation(
        parent: animation,
        curve: curve,
        reverseCurve: reverseCurve ?? curve.flipped,
      );
      final secondaryCurved = CurvedAnimation(
        parent: secondaryAnimation,
        curve: curve,
        reverseCurve: reverseCurve ?? curve.flipped,
      );

      return FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(secondaryCurved),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 1.0,
            end: exitScale,
          ).animate(secondaryCurved),
          child: FadeTransition(
            opacity: primaryCurved,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: beginScale,
                end: 1.0,
              ).animate(primaryCurved),
              child: child,
            ),
          ),
        ),
      );
    };
  }

  static AdaptiveTransitionsBuilder _sharedAxisTranslation({
    required Offset beginOffset,
    required Offset exitOffset,
    required Curve curve,
    Curve? reverseCurve,
  }) {
    return (context, animation, secondaryAnimation, child) {
      final primaryCurved = CurvedAnimation(
        parent: animation,
        curve: curve,
        reverseCurve: reverseCurve ?? curve.flipped,
      );
      final secondaryCurved = CurvedAnimation(
        parent: secondaryAnimation,
        curve: curve,
        reverseCurve: reverseCurve ?? curve.flipped,
      );

      return AnimatedBuilder(
        animation: Listenable.merge([primaryCurved, secondaryCurved]),
        builder: (context, builtChild) {
          final enterProgress = primaryCurved.value;
          final exitProgress = secondaryCurved.value;
          final dx =
              beginOffset.dx * (1.0 - enterProgress) +
              exitOffset.dx * exitProgress;
          final dy =
              beginOffset.dy * (1.0 - enterProgress) +
              exitOffset.dy * exitProgress;
          final opacity = (enterProgress * (1.0 - exitProgress)).clamp(
            0.0,
            1.0,
          );
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(dx, dy),
              child: builtChild,
            ),
          );
        },
        child: child,
      );
    };
  }
}
