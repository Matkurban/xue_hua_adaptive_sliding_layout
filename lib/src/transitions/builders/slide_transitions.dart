import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route.dart';

/// 滑动类与 Cupertino 风格页面过渡构建器集合。
abstract final class SlidePageTransitions {
  /// 从指定方向滑入，可选底层页面视差位移。
  static AdaptiveTransitionsBuilder slide({
    required Offset beginOffset,
    Offset? secondaryEndOffset,
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) {
    return (context, animation, secondaryAnimation, child) {
      final primaryCurved = CurvedAnimation(
        parent: animation,
        curve: curve,
        reverseCurve: reverseCurve ?? curve.flipped,
      );
      Widget result = SlideTransition(
        position: Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(primaryCurved),
        child: child,
      );
      if (secondaryEndOffset != null) {
        final secondaryCurved = CurvedAnimation(
          parent: secondaryAnimation,
          curve: curve,
          reverseCurve: reverseCurve ?? curve.flipped,
        );
        result = SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: secondaryEndOffset,
          ).animate(secondaryCurved),
          child: result,
        );
      }
      return result;
    };
  }

  /// 从右侧滑入（自右向左），带底层视差左移。
  static AdaptiveTransitionsBuilder slideRightToLeft({
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
    bool parallax = true,
  }) {
    return slide(
      beginOffset: const Offset(1.0, 0.0),
      secondaryEndOffset: parallax ? const Offset(-0.25, 0.0) : null,
      curve: curve,
      reverseCurve: reverseCurve,
    );
  }

  /// 从左侧滑入（自左向右），带底层视差右移。
  static AdaptiveTransitionsBuilder slideLeftToRight({
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
    bool parallax = true,
  }) {
    return slide(
      beginOffset: const Offset(-1.0, 0.0),
      secondaryEndOffset: parallax ? const Offset(0.25, 0.0) : null,
      curve: curve,
      reverseCurve: reverseCurve,
    );
  }

  /// 从底部向上滑入。
  static AdaptiveTransitionsBuilder slideBottomToTop({
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) {
    return slide(
      beginOffset: const Offset(0.0, 1.0),
      curve: curve,
      reverseCurve: reverseCurve,
    );
  }

  /// 从顶部向下滑入。
  static AdaptiveTransitionsBuilder slideTopToBottom({
    Curve curve = Curves.easeOutCubic,
    Curve? reverseCurve,
  }) {
    return slide(
      beginOffset: const Offset(0.0, -1.0),
      curve: curve,
      reverseCurve: reverseCurve,
    );
  }

  /// iOS / macOS 原生 Cupertino 右滑视差过渡（主路由从右侧滑入，底层路由左移 1/3 视差）。
  static AdaptiveTransitionsBuilder cupertino({
    bool linearTransition = false,
    Curve curve = Curves.linearToEaseOut,
    Curve? reverseCurve,
  }) {
    return (context, animation, secondaryAnimation, child) {
      final effectiveCurve = linearTransition ? Curves.linear : curve;
      final effectiveReverse = linearTransition
          ? Curves.linear
          : (reverseCurve ?? Curves.easeInToLinear);
      final primaryPosition =
          Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: effectiveCurve,
              reverseCurve: effectiveReverse,
            ),
          );
      final secondaryPosition =
          Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-1.0 / 3.0, 0.0),
          ).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: effectiveCurve,
              reverseCurve: effectiveReverse,
            ),
          );
      final textDirection =
          Directionality.maybeOf(context) ?? TextDirection.ltr;
      return SlideTransition(
        position: secondaryPosition,
        textDirection: textDirection,
        transformHitTests: false,
        child: SlideTransition(
          position: primaryPosition,
          textDirection: textDirection,
          child: child,
        ),
      );
    };
  }
}
