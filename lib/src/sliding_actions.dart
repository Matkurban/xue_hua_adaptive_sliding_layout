import 'package:flutter/widgets.dart';

/// 向子树注入滑动栈出栈动作（AppBar 返回、Escape、[SlidingBackButton]）。
///
/// 由 [MultiColumnScaffold] 写入，通常接到 [AdaptiveNavigator.pop]。
class SlidingActions extends InheritedWidget {
  /// [pop] 为统一出栈；栏内控件不应直接依赖宿主路由类。
  const SlidingActions({super.key, required this.pop, required super.child});

  /// 弹出当前滑动栈顶（或由宿主映射到 fallback pop）。
  final VoidCallback pop;

  /// 位于注入过 [SlidingActions] 的子树内时返回，否则 null。
  static SlidingActions? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SlidingActions>();
  }

  /// 读取 [SlidingActions]；未注入时 assert。
  static SlidingActions of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'SlidingActions not found');
    return scope!;
  }

  /// [pop] 回调实例变化时通知依赖。
  @override
  bool updateShouldNotify(SlidingActions oldWidget) => pop != oldWidget.pop;
}
