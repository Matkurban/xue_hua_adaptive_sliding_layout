/// 自适应移动端 / 桌面端多栏滑动布局与声明式路由。
///
/// 一张路由表决定 URL、页面栈和栏位；调用 API 与 [NavigatorState] 同名
///（`AdaptiveRouter.of(context).pushNamed(...)`）。不依赖 go_router，
/// 路由 / DI 由宿主自己持有路由器实例。
library;

export 'src/layout/breadcrumbs.dart';
export 'src/layout/layout_breakpoints.dart';
export 'src/layout/pane_scope.dart';
export 'src/layout/sliding_pane_viewport.dart';
export 'src/router/adaptive_router.dart';
export 'src/router/match.dart';
export 'src/router/route.dart';
export 'src/router/route_state.dart';
