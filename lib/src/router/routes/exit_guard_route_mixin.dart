import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_router.dart';

/// 页面路由的 onExit 守卫：先让页内 PopScope 表态，再由 onExit 否决，二者互不覆盖。
mixin ExitGuardRouteMixin<T> on ModalRoute<T> {
  AdaptiveRouter get router;

  AdaptiveRouteMatch get match;

  /// 不含 onExit 否决的 disposition；doNotPop 即页内 PopScope 否决。
  RoutePopDisposition get scopeDisposition => super.popDisposition;

  @override
  RoutePopDisposition get popDisposition {
    final inner = super.popDisposition;
    return match.route.onExit != null && inner == RoutePopDisposition.pop
        ? RoutePopDisposition.doNotPop
        : inner;
  }

  @override
  void onPopInvokedWithResult(bool didPop, T? result) {
    super.onPopInvokedWithResult(didPop, result);
    if (didPop) {
      router.handleRemovedPageKey(match.pageKey, result);
    } else if (match.route.onExit != null &&
        scopeDisposition != RoutePopDisposition.doNotPop) {
      unawaited(router.exitThenPop(match, result));
    }
  }
}
