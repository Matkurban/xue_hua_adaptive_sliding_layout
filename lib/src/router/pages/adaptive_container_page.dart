import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/routes/keep_underlying_ticker_route.dart';

/// 壳层与容器页（如根 Navigator 上的 `adaptive-shell` 与壳层 `_chromeNavKey` 上的
/// `adaptive-chrome`），接入 [KeepUnderlyingTickerRoute]，在上层不透明路由完成
/// 入场转场后自动将底层壳与根页面标记为 offstage。
class AdaptiveContainerPage<T> extends Page<T> {
  const AdaptiveContainerPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return AdaptiveContainerRoute<T>(page: this);
  }
}

/// 壳层与容器页对应的 [PageRoute]。
class AdaptiveContainerRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T>, KeepUnderlyingTickerRoute<T> {
  AdaptiveContainerRoute({required AdaptiveContainerPage<T> page})
    : super(settings: page);

  AdaptiveContainerPage<T> get _page => settings as AdaptiveContainerPage<T>;

  @override
  Widget buildContent(BuildContext context) => wrapOffstageContent(_page.child);

  @override
  bool get maintainState => true;
}
