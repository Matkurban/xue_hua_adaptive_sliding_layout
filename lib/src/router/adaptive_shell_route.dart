import 'package:flutter/widgets.dart';

import '../layout/breadcrumbs.dart';
import '../layout/layout_breakpoints.dart';
import '../layout/pane_scope.dart';
import '../layout/sliding_pane_viewport.dart';
import 'adaptive_branch.dart';
import 'adaptive_route_base.dart';
import 'adaptive_shell_state.dart';

/// 壳层工厂。[child] 为当前分支的栏位 / Navigator。
typedef AdaptiveShellBuilder =
    Widget Function(
      BuildContext context,
      AdaptiveShellState shell,
      Widget child,
    );

/// 多分支壳：宽度决定 1 栏 Navigator 还是 2 栏滑动视口。
///
/// `ponytail:` 整棵路由树只允许一个本类型，出现在顶层。嵌套壳需要另开分支模型。
class AdaptiveShellRoute extends AdaptiveRouteBase {
  /// [builder] 画 rail / bottom bar；[branches] 为各 Tab 的路由树。
  AdaptiveShellRoute({
    required this.builder,
    required this.branches,
    this.breakpoints = const LayoutBreakpoints(),
    this.showBreadcrumbs = true,
    this.resizable = true,
    this.initialLeftPaneFraction = 0.5,
    this.minLeftPaneFraction = 0.3,
    this.minRightPaneFraction = 0.3,
    this.onLeftPaneFractionChanged,
    this.breadcrumbsBuilder,
    this.placeholder,
    this.paneBuilder,
    this.resizeHandleBuilder,
    this.slideDuration = SlidingPaneViewport.defaultSlideDuration,
    this.slideCurve = SlidingPaneViewport.defaultSlideCurve,
    this.escapePops = true,
  }) : assert(
         branches.isNotEmpty,
         'AdaptiveShellRoute.branches must not be empty',
       );

  /// 宿主壳 UI。必须把 [child] 放到内容区。
  final AdaptiveShellBuilder builder;

  /// 各 Tab。按声明顺序对应 [AdaptiveShellState.currentIndex]。
  final List<AdaptiveBranch> branches;

  /// 栏数断点。
  final LayoutBreakpoints breakpoints;

  /// expanded 下是否在视口上方画整栈面包屑。
  final bool showBreadcrumbs;

  /// 双栏时是否显示分割条。
  final bool resizable;

  /// 左栏初始比例。
  final double initialLeftPaneFraction;

  /// 左栏最小比例。
  final double minLeftPaneFraction;

  /// 右栏最小比例（决定左栏上限）。
  final double minRightPaneFraction;

  /// 分割条松手时的新比例。
  final ValueChanged<double>? onLeftPaneFractionChanged;

  /// 非空时替换默认 [AdaptiveBreadcrumbs]；仍受 [showBreadcrumbs] 控制。
  final AdaptiveBreadcrumbsBuilder? breadcrumbsBuilder;

  /// 壳级默认右栏占位。[AdaptiveBranch.placeholder] 优先。
  final AdaptivePlaceholderBuilder? placeholder;

  /// 包每一栏；透传到 [SlidingPaneViewport.paneBuilder]。
  final SlidingPaneFrameBuilder? paneBuilder;

  /// 只换分割条视觉；透传到 [SlidingPaneViewport.resizeHandleBuilder]。
  final WidgetBuilder? resizeHandleBuilder;

  /// 栏位平移动画时长。
  final Duration slideDuration;

  /// 栏位平移动画曲线。
  final Curve slideCurve;

  /// 为 false 时 Escape 不再调用 [AdaptiveRouter.maybePop]。
  final bool escapePops;
}
