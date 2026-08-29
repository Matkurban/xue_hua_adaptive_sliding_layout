import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_window_controller.dart';

/// 当前 [context] 是否位于桌面多栏滑动窗口内。
///
/// 栏内嵌套 Navigator 的 Overlay 会被栏边界裁剪，菜单/遮罩应提升到根 Overlay。
bool inSlidingWindow(BuildContext context) =>
    SlidingWindowScope.maybeOf(context) != null;

/// 向子树暴露当前 Tab 的滑动窗口控制器。
class SlidingWindowScope extends InheritedWidget {
  /// [controller] 为本 Tab 的栈，通常由 [MultiColumnScaffold] 写入。
  const SlidingWindowScope({
    super.key,
    required this.controller,
    required super.child,
  });

  /// 当前 Tab 的 [SlidingWindowController]。
  final SlidingWindowController controller;

  /// 位于滑动壳内时返回 scope，否则 null。
  static SlidingWindowScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SlidingWindowScope>();
  }

  /// 读取 [SlidingWindowScope]；不在壳内时 assert。
  static SlidingWindowScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'SlidingWindowScope not found');
    return scope!;
  }

  /// [controller] 实例变化时通知依赖。
  @override
  bool updateShouldNotify(SlidingWindowScope oldWidget) =>
      controller != oldWidget.controller;
}

/// 当前栏在滑动栈中的位置。返回按钮只应出现在栈顶（最右可见栏）。
class SlidingPaneScope extends InheritedWidget {
  /// [index] 为栈下标（0 为根），[depth] 为当前栈深度。
  const SlidingPaneScope({
    super.key,
    required this.index,
    required this.depth,
    required super.child,
  });

  /// 本栏在栈中的下标（0 为根）。[AdaptiveNavigator.push] 的 `from` 用它算 keepCount。
  final int index;

  /// 当前栈深度。
  final int depth;

  /// 本栏是否为栈顶（最右逻辑页，不一定是根）。
  bool get isStackTop => isStackTopFor(index: index, depth: depth);

  /// 栈顶且不是根页时显示返回。
  bool get showBack => showBackFor(index: index, depth: depth);

  /// [index] 是否等于 [depth] - 1。
  static bool isStackTopFor({required int index, required int depth}) {
    return depth > 0 && index == depth - 1;
  }

  /// 深度大于 1 且 [index] 是栈顶时为 true。
  static bool showBackFor({required int index, required int depth}) {
    return depth > 1 && index == depth - 1;
  }

  /// 位于某栏内时返回 scope，否则 null。
  static SlidingPaneScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SlidingPaneScope>();
  }

  /// 读取 [SlidingPaneScope]；不在栏内时 assert。
  static SlidingPaneScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'SlidingPaneScope not found');
    return scope!;
  }

  /// 下标或深度变化时通知依赖（返回钮、from 分流）。
  @override
  bool updateShouldNotify(SlidingPaneScope oldWidget) {
    return index != oldWidget.index || depth != oldWidget.depth;
  }
}
