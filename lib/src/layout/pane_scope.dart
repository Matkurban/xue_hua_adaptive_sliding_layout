import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 包每一栏（含右侧占位槽）。[index] 为栈下标；等于 `panes.length` 时是占位槽。
typedef SlidingPaneFrameBuilder =
    Widget Function(BuildContext context, int index, Widget child);

/// 双栏视口中的一栏：key 保活、title 驱动面包屑、child 为栏内页面。
class SlidingPane {
  /// [key] 必须在深度变化时保持稳定，栏内 State 才不会重建。
  const SlidingPane({
    required this.key,
    required this.title,
    required this.child,
  });

  /// 与 [AdaptiveRouteMatch.pageKey] 对齐。
  final LocalKey key;

  /// 面包屑标题，页面可写成 `AdaptivePaneScope.maybeOf(context)?.title.value = …`。
  final Signal<String> title;

  /// 栏内页面，由栏内 Navigator 挂载。
  final Widget child;
}

/// 当前栏在滑动栈中的位置。仅双栏栏位内非 null。
///
/// 替代 2.x 的 `inSlidingWindow` / `SlidingPaneScope` / `SlidingPageTitle`：
/// 用 [maybeOf] 判断是否在栏内；改标题写 [title]；出栈调 [pop]。
class AdaptivePaneScope extends InheritedWidget {
  /// [index] 为栈下标（0 为根），[depth] 为当前栈深度。
  const AdaptivePaneScope({
    super.key,
    required this.index,
    required this.depth,
    required this.title,
    required this.pop,
    required super.child,
  });

  /// 本栏在栈中的下标（0 为根）。
  final int index;

  /// 当前栈深度。
  final int depth;

  /// 本栏面包屑标题。
  final Signal<String> title;

  /// 弹出栈顶。通常接到 [AdaptiveRouter.maybePop]。
  final VoidCallback pop;

  /// 本栏是否为栈顶。
  bool get isTop => depth > 0 && index == depth - 1;

  /// 栈顶且不是根页时显示返回。
  bool get showBack => depth > 1 && isTop;

  /// 位于某栏内时返回，否则 null（1 栏模式、覆盖层、壳外）。
  static AdaptivePaneScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdaptivePaneScope>();
  }

  /// 读取本栏 scope；不在栏内时 assert。
  static AdaptivePaneScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'AdaptivePaneScope not found');
    return scope!;
  }

  /// 下标、深度或 pop 回调变化时通知（返回钮）。
  @override
  bool updateShouldNotify(AdaptivePaneScope oldWidget) {
    return index != oldWidget.index ||
        depth != oldWidget.depth ||
        pop != oldWidget.pop ||
        title != oldWidget.title;
  }
}
