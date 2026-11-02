import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match_list.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/internal/navigation_layer.dart';

/// 解析弹层（dialog / sheet / menu）与托管页面路由之间的遮挡和层级关系。
class PopupLayerResolver {
  PopupLayerResolver(this._hostRoutes);

  final Map<LocalKey, ModalRoute<dynamic>> _hostRoutes;

  /// 判断 [context] 落在哪一层，供 `popFrom` / `maybePopFrom` 决定操作目标。
  NavigationLayer layerOf(
    BuildContext context,
    AdaptiveRouteMatchList current,
  ) {
    final route = ModalRoute.of(context);
    if (route == null) return const GlobalNavigationLayer();
    if (!_hostRoutes.containsValue(route)) {
      // 托管页面之外：pageless 的是 dialog / sheet / menu，带 Page 的是壳层容器页。
      final nav = route.navigator;
      if (route.settings is Page || nav == null) {
        return const GlobalNavigationLayer();
      }
      return PopupNavigationLayer(nav);
    }
    final popup = popupOver(route);
    if (popup != null) return PopupNavigationLayer(popup);
    final top = current.last;
    if (top != null && identical(_hostRoutes[top.pageKey], route)) {
      return const TopPageNavigationLayer();
    }
    return const IdleNavigationLayer();
  }

  /// 盖住栈顶页的 pageless 路由（dialog、sheet、menu）所在的 [NavigatorState]；没有则 null。
  ///
  /// 只看栈顶页那一栏及其祖先（壳层、根）；双栏时另一栏的栏内弹层由 `popFrom` /
  /// `maybePopFrom` 处理。
  NavigatorState? popupNavigator(AdaptiveRouteMatchList current) {
    final top = current.last;
    final host = top == null ? null : _hostRoutes[top.pageKey];
    return host == null ? null : popupOver(host);
  }

  /// 盖住 [page] 的弹层所在 Navigator：先祖先链（根、壳层，外层优先，因为外层弹层
  /// 盖住一切），再 [page] 自己的 Navigator。栏内 local history 不算弹层，因为它不会
  /// 让页面路由失去 [ModalRoute.isCurrent]。
  NavigatorState? popupOver(ModalRoute<dynamic> page) {
    NavigatorState? found;
    var nav = page.navigator;
    final seen = <NavigatorState>{};
    while (nav != null && seen.add(nav)) {
      // 布局切换后旧 Navigator 可能已卸载，不能再向上查祖先。
      if (!nav.mounted) break;
      final parent = ModalRoute.of(nav.context);
      if (parent == null) break;
      if (_coveredByPopup(parent)) found = parent.navigator;
      nav = parent.navigator;
    }
    return found ?? (_coveredByPopup(page) ? page.navigator : null);
  }

  /// [route] 本该在其 Navigator 顶上却被压住，且压住它的不是本路由器托管的页面。
  bool _coveredByPopup(ModalRoute<dynamic> route) {
    final nav = route.navigator;
    if (nav == null || route.isCurrent || !nav.canPop()) return false;
    return !_hostRoutes.values.any(
      (page) => identical(page.navigator, nav) && page.isCurrent,
    );
  }

  /// 逐个关掉盖住页面的弹层，页面栈不动。
  ///
  /// 最多 32 层。再多说明 [Navigator.pop] 没拆掉路由，停下来避免空转。
  void dismissPopups(AdaptiveRouteMatchList current) {
    for (var i = 0; i < 32; i++) {
      final popup = popupNavigator(current);
      if (popup == null) return;
      popup.pop<Object?>();
    }
  }
}
