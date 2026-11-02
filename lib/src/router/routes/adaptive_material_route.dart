import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_router.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/pages/adaptive_page.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/routes/exit_guard_route_mixin.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/routes/keep_underlying_ticker_route.dart';

/// 与 Flutter 私有 `_PageBasedMaterialPageRoute` 对齐的 Material 页路由。
class AdaptiveMaterialRoute<T> extends PageRoute<T>
    with
        MaterialRouteTransitionMixin<T>,
        ExitGuardRouteMixin<T>,
        KeepUnderlyingTickerRoute<T> {
  AdaptiveMaterialRoute({required AdaptivePage<T> page})
    : super(
        settings: page,
        fullscreenDialog: page.match.route.fullscreenDialog,
      );

  AdaptivePage<T> get _page => settings as AdaptivePage<T>;

  @override
  AdaptiveRouter get router => _page.router;

  @override
  AdaptiveRouteMatch get match => _page.match;

  @override
  bool get opaque => match.route.opaque;

  @override
  Widget buildContent(BuildContext context) => wrapOffstageContent(_page.child);

  @override
  bool get maintainState => true;
}
