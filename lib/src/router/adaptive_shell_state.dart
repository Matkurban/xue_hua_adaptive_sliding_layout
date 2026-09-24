import 'package:signals_flutter/signals_flutter.dart';

import '../layout/layout_breakpoints.dart';

/// [AdaptiveShellRoute.builder] 收到的壳层状态：当前分支、宽度、断点、分割比例。
class AdaptiveShellState {
  /// [goBranch] 切换 Tab；[leftPaneFraction] 为各 Tab 共用的左栏比例 signal。
  AdaptiveShellState({
    required this.currentIndex,
    required this.branchCount,
    required this.width,
    required this.breakpoints,
    required this.leftPaneFraction,
    required this.goBranch,
  });

  /// 当前选中的 [AdaptiveBranch] 下标。
  final int currentIndex;

  /// 分支总数。
  final int branchCount;

  /// [LayoutBuilder] 测到的壳层宽度。
  final double width;

  /// 本壳使用的断点。
  final LayoutBreakpoints breakpoints;

  /// 双栏左栏比例。松手后写回，拖拽中由视口本地更新。
  final Signal<double> leftPaneFraction;

  /// 切到 [index] 对应分支。
  ///
  /// [initialLocation] 为 true 时忽略该分支上次位置，回到
  /// [AdaptiveBranch.initialLocation]。
  final void Function(int index, {bool initialLocation}) goBranch;

  /// 当前宽度是否低于 compact。
  bool get isCompact => breakpoints.isCompact(width);

  /// 当前宽度是否为 medium。
  bool get isMedium => breakpoints.isMedium(width);

  /// 当前宽度是否达到 expanded。
  bool get isExpanded => breakpoints.isExpanded(width);

  /// 视口应显示的栏数（1 或 2）。
  int get visibleColumnCount => breakpoints.visibleColumnCount(width);
}
