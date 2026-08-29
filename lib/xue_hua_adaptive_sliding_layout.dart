/// 自适应移动端 / 桌面端多栏滑动布局与命名路由拦截。
///
/// 宿主拥有路由、DI、l10n；本库只导出断点、每 Tab 滑动栈、视口和
/// [AdaptiveNavigator]。接入步骤与参数说明见仓库根目录 README。
///
/// 导出类型按职责：
/// - 断点：[LayoutBreakpoints]（别名 [AppBreakpoints]）
/// - 多 Tab 壳：[SlidingShell]
/// - 单 Tab 栈：[SlidingWindowController]、[SlidingWindowPage]
/// - 布局：[MultiColumnScaffold]、[SlidingWindowViewport]
/// - 导航：[AdaptiveNavigator]、[AdaptiveNavigatorFallback]、[AdaptiveRouteArgs]
/// - 栏内辅助：[SlidingActions]、[SlidingBackButton]、[SlidingPageTitle]、
///   [SlidingWindowScope]、[SlidingPaneScope]、[inSlidingWindow]
library;

export 'src/adaptive_navigator.dart';
export 'src/layout_breakpoints.dart';
export 'src/multi_column_scaffold.dart';
export 'src/sliding_actions.dart';
export 'src/sliding_back_button.dart';
export 'src/sliding_page_title.dart';
export 'src/sliding_shell.dart';
export 'src/sliding_window_controller.dart';
export 'src/sliding_window_page.dart';
export 'src/sliding_window_scope.dart';
export 'src/sliding_window_viewport.dart';
