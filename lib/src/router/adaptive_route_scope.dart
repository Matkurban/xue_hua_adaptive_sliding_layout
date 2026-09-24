import 'package:flutter/widgets.dart';

import 'adaptive_route_state.dart';

/// 向子树暴露 [AdaptiveRouteState]。
class AdaptiveRouteScope extends InheritedWidget {
  /// [state] 为本页匹配快照。
  const AdaptiveRouteScope({
    super.key,
    required this.state,
    required super.child,
  });

  /// 当前页的路由快照。
  final AdaptiveRouteState state;

  /// 子树内返回 [state]，否则 null。
  static AdaptiveRouteState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdaptiveRouteScope>()
        ?.state;
  }

  /// [state] 的 uri / 参数变化时通知。
  @override
  bool updateShouldNotify(AdaptiveRouteScope oldWidget) =>
      state.uri != oldWidget.state.uri ||
      state.matchedLocation != oldWidget.state.matchedLocation ||
      state.arguments != oldWidget.state.arguments ||
      state.error != oldWidget.state.error;
}
