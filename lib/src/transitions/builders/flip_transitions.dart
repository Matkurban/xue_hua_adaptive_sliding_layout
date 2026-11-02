import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route.dart';

/// 3D 透视翻转类页面过渡构建器集合。
abstract final class FlipPageTransitions {
  /// 3D 水平翻转（绕 Y 轴从 -90° 旋转至 0° 伴随透明度过渡）。
  static AdaptiveTransitionsBuilder horizontal({
    double perspective = 0.001,
    Curve curve = Curves.easeInOutCubic,
    Curve? reverseCurve,
  }) {
    return _flip(
      axis: Axis.horizontal,
      perspective: perspective,
      curve: curve,
      reverseCurve: reverseCurve,
    );
  }

  /// 3D 垂直翻转（绕 X 轴从 90° 旋转至 0° 伴随透明度过渡）。
  static AdaptiveTransitionsBuilder vertical({
    double perspective = 0.001,
    Curve curve = Curves.easeInOutCubic,
    Curve? reverseCurve,
  }) {
    return _flip(
      axis: Axis.vertical,
      perspective: perspective,
      curve: curve,
      reverseCurve: reverseCurve,
    );
  }

  static AdaptiveTransitionsBuilder _flip({
    required Axis axis,
    required double perspective,
    required Curve curve,
    Curve? reverseCurve,
  }) {
    return (context, animation, secondaryAnimation, child) {
      final primaryCurved = CurvedAnimation(
        parent: animation,
        curve: curve,
        reverseCurve: reverseCurve ?? curve.flipped,
      );
      return AnimatedBuilder(
        animation: primaryCurved,
        builder: (context, builtChild) {
          final value = primaryCurved.value;
          final angle = (1.0 - value) * (math.pi / 2);
          final transform = Matrix4.identity()..setEntry(3, 2, perspective);
          if (axis == Axis.horizontal) {
            transform.rotateY(-angle);
          } else {
            transform.rotateX(angle);
          }
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: transform,
              child: builtChild,
            ),
          );
        },
        child: child,
      );
    };
  }
}
