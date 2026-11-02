import 'package:flutter/widgets.dart';

/// 壳内 Navigator 的转场代理：跨断点搬家那一帧，旧页面立即移除（不播退出
/// 动画）、新页面直接加入，这样同一个 GlobalKey 的子树在同一帧里从旧
/// Navigator 交接给新 Navigator，不会两边同时挂载。
class RelocationTransitionDelegate extends DefaultTransitionDelegate<dynamic> {
  RelocationTransitionDelegate(this._relocating);

  final bool Function() _relocating;

  @override
  Iterable<RouteTransitionRecord> resolve({
    required List<RouteTransitionRecord> newPageRouteHistory,
    required Map<RouteTransitionRecord?, RouteTransitionRecord>
    locationToExitingPageRoute,
    required Map<RouteTransitionRecord?, List<RouteTransitionRecord>>
    pageRouteToPagelessRoutes,
  }) {
    if (!_relocating()) {
      return super.resolve(
        newPageRouteHistory: newPageRouteHistory,
        locationToExitingPageRoute: locationToExitingPageRoute,
        pageRouteToPagelessRoutes: pageRouteToPagelessRoutes,
      );
    }
    final results = <RouteTransitionRecord>[];
    void exiting(RouteTransitionRecord? location) {
      final route = locationToExitingPageRoute[location];
      if (route == null) return;
      if (route.isWaitingForExitingDecision) {
        route.markForComplete(route.route.currentResult);
        for (final pageless in pageRouteToPagelessRoutes[route] ?? const []) {
          if (pageless.isWaitingForExitingDecision) {
            pageless.markForComplete(pageless.route.currentResult);
          }
        }
      }
      results.add(route);
      exiting(route);
    }

    exiting(null);
    for (final route in newPageRouteHistory) {
      if (route.isWaitingForEnteringDecision) route.markForAdd();
      results.add(route);
      exiting(route);
    }
    return results;
  }
}
