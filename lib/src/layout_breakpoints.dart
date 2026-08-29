/// 全局布局断点：只看窗口宽度，不看设备类型或方向。
///
/// 三档：compact（低于 [compactMaxWidth]）滑动栈关闭；
/// medium（介于两者之间）滑动栈开启、单栏；
/// expanded（达到 [expandedMinWidth]）滑动栈开启、双栏。
sealed class LayoutBreakpoints {
  /// compact 上界（不含）。[width] 低于此值为窄屏，走宿主导航。
  static const double compactMaxWidth = 600;

  /// expanded 下界（含）。达到此宽度时视口显示两栏。
  static const double expandedMinWidth = 840;

  /// [width] 是否低于 compact 上界。
  static bool isCompact(double width) => width < compactMaxWidth;

  /// [width] 是否达到 expanded 下界。
  static bool isExpanded(double width) => width >= expandedMinWidth;

  /// 宽屏双栏，否则单栏（含 compact 与 medium）。
  static int visibleColumnCount(double width) => isExpanded(width) ? 2 : 1;
}

/// 与历史 [AppBreakpoints] 名称兼容，实现即为 [LayoutBreakpoints]。
typedef AppBreakpoints = LayoutBreakpoints;
