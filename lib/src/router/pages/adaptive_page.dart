import 'package:flutter/foundation.dart' show mapEquals;
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_router.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/routes/adaptive_material_route.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/routes/adaptive_transition_route.dart';

/// 声明式页：Material 过场或自定义 [AdaptiveRoute.transitionsBuilder] / [AdaptiveRoute.transitionType]。
class AdaptivePage<T> extends Page<T> {
  const AdaptivePage({
    required this.router,
    required this.match,
    required this.child,
    this.branchIndex = 0,
    this.error,
    super.key,
    super.name,
    super.arguments,
  });

  final AdaptiveRouter router;
  final AdaptiveRouteMatch match;
  final Widget child;
  final int branchIndex;
  final Exception? error;

  bool shouldRebuild(AdaptivePage<T> oldPage) {
    return branchIndex != oldPage.branchIndex ||
        name != oldPage.name ||
        !identical(arguments, oldPage.arguments) ||
        !mapEquals(match.queryParameters, oldPage.match.queryParameters) ||
        error != oldPage.error;
  }

  /// 解析当前页最终生效的过渡构建器。
  AdaptiveTransitionsBuilder? get effectiveTransitionsBuilder {
    final shell = match.isOverlay ? null : router.shell;
    return match.route.effectiveTransitionsBuilder(
      shellTransitionType: shell?.transitionType,
      shellTransitionsBuilder: shell?.transitionsBuilder,
      shellTransitionCurve: shell?.transitionCurve,
      shellReverseTransitionCurve: shell?.reverseTransitionCurve,
      routerTransitionType: router.defaultTransitionType,
      routerTransitionsBuilder: router.defaultTransitionsBuilder,
      routerTransitionCurve: router.defaultTransitionCurve,
      routerReverseTransitionCurve: router.defaultReverseTransitionCurve,
    );
  }

  /// 解析当前页最终生效的入场动画时长。
  Duration get effectiveTransitionDuration {
    final shell = match.isOverlay ? null : router.shell;
    return match.route.effectiveTransitionDuration(
      shellTransitionDuration: shell?.transitionDuration,
      shellTransitionType: shell?.transitionType,
      routerTransitionDuration: router.defaultTransitionDuration,
      routerTransitionType: router.defaultTransitionType,
    );
  }

  /// 解析当前页最终生效的退场动画时长。
  Duration get effectiveReverseTransitionDuration {
    final shell = match.isOverlay ? null : router.shell;
    return match.route.effectiveReverseTransitionDuration(
      shellReverseTransitionDuration: shell?.reverseTransitionDuration,
      shellTransitionDuration: shell?.transitionDuration,
      shellTransitionType: shell?.transitionType,
      routerReverseTransitionDuration: router.defaultReverseTransitionDuration,
      routerTransitionDuration: router.defaultTransitionDuration,
      routerTransitionType: router.defaultTransitionType,
    );
  }

  @override
  Route<T> createRoute(BuildContext context) {
    final builder = effectiveTransitionsBuilder;
    if (builder != null) {
      return AdaptiveTransitionRoute<T>(
        page: this,
        transitionsBuilder: builder,
        transitionDuration: effectiveTransitionDuration,
        reverseTransitionDuration: effectiveReverseTransitionDuration,
      );
    }
    return AdaptiveMaterialRoute<T>(page: this);
  }
}
