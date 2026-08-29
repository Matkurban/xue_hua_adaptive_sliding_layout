import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout_breakpoints.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_window_controller.dart';

/// 多 Tab 滑动壳：每 Tab 一个 [SlidingWindowController]，按窗口宽度决定是否拦截。
///
/// 必须先 [init] 再读 [stacks] / [isSlidingActive]。宿主在 [LayoutBuilder] 里
/// 调用 [updateViewportWidth]；拆除时 [dispose]。
class SlidingShell {
  /// [tabCount] 为将要创建的栈数量，须 ≥ 1。
  SlidingShell({required this.tabCount});

  /// `init()` 时生成的 controller 个数，与宿主 Tab 一一对应。
  final int tabCount;

  /// 当前选中的 Tab 下标，默认 `0`。[changePage] 只改这个值，不 pop 各栈。
  final Signal<int> currentIndex = signal(0);

  /// 最近一次 [updateViewportWidth] 写入的窗口宽度，供断点计算。
  final Signal<double> viewportWidth = signal(0);

  /// 各 Tab 共用的双栏左栏比例。松手后由宿主写回，拖拽中由视口本地更新。
  final Signal<double> leftPaneFraction = signal(0.5);

  /// [init] 之后才可用的每 Tab 栈列表。
  late final List<SlidingWindowController> stacks;

  /// 是否已 [init] 且尚未 [dispose]。
  bool _initialized = false;

  /// 是否已 [init] 且尚未 [dispose]。
  bool get isInitialized => _initialized;

  /// 当前宽度是否低于 compact 上界。
  bool get isCompact => LayoutBreakpoints.isCompact(viewportWidth.value);

  /// 当前宽度是否达到 expanded（双栏）。
  bool get isExpanded => LayoutBreakpoints.isExpanded(viewportWidth.value);

  /// 已初始化且窗口达到中屏及以上时，子页进入滑动栈。
  bool get isSlidingActive => _initialized && !isCompact;

  /// 当前宽度下视口应显示的栏数（expanded 为 2，否则 1）。
  int get visibleColumnCount => LayoutBreakpoints.visibleColumnCount(viewportWidth.value);

  /// 当前 Tab 的滑动栈。须在 [init] 之后访问。
  SlidingWindowController get currentStack => stacks[currentIndex.value];

  /// 为每个 Tab 分配空栈。读 [stacks] 或把 [isSlidingActive] 交给导航之前调用。
  void init() {
    stacks = List<SlidingWindowController>.generate(tabCount, (_) => SlidingWindowController());
    _initialized = true;
  }

  /// 把窗口宽度同步进 [viewportWidth]；值未变则跳过，避免无谓重建。
  void updateViewportWidth(double width) {
    if (viewportWidth.value == width) return;
    viewportWidth.value = width;
  }

  /// 切换当前 Tab。各栈内容保留，只改 [currentIndex]。
  void changePage(int index) {
    currentIndex.value = index;
  }

  /// 完成各页未决 Future、销毁 controller，并标记未初始化。
  void dispose() {
    _initialized = false;
    for (final stack in stacks) {
      stack.dispose();
    }
  }
}
