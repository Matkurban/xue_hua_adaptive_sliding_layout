/// 宽度断点：只看窗口宽度，不看设备类型或方向。
///
/// 三档：compact（低于 [compactMaxWidth]）单栏全屏 [Navigator] 栈；
/// medium（介于两者之间）仍是单栏 [Navigator]，供宿主区分 rail / bottom bar；
/// expanded（达到 [expandedMinWidth]）双栏滑动视口。
///
/// `ponytail:` 视口只支持 1 / 2 栏。三栏及以上改 [visibleColumnCount]
/// 并让 [SlidingPaneViewport] 按 N 栏布局。
class LayoutBreakpoints {
  /// [compactMaxWidth] 默认 600，[expandedMinWidth] 默认 840（Material 中档）。
  const LayoutBreakpoints({
    this.compactMaxWidth = 600,
    this.expandedMinWidth = 840,
  });

  /// compact 上界（不含）。低于此值走单栏全屏 [Navigator] 栈。
  final double compactMaxWidth;

  /// expanded 下界（含）。达到此宽度时视口显示两栏。
  final double expandedMinWidth;

  /// [width] 是否低于 compact 上界。
  bool isCompact(double width) => width < compactMaxWidth;

  /// [width] 是否处于 compact 与 expanded 之间。栏数仍为 1，与 compact 相同。
  bool isMedium(double width) =>
      width >= compactMaxWidth && width < expandedMinWidth;

  /// [width] 是否达到 expanded 下界。
  bool isExpanded(double width) => width >= expandedMinWidth;

  /// expanded 为 2，否则 1。
  int visibleColumnCount(double width) => isExpanded(width) ? 2 : 1;
}
