import 'package:flutter/widgets.dart';

import 'adaptive_shell_state.dart';

/// 向子树暴露 [AdaptiveShellState]。
class AdaptiveShellScope extends InheritedWidget {
  /// [state] 由内部壳层在每次 layout 时重建。
  const AdaptiveShellScope({
    super.key,
    required this.state,
    required super.child,
  });

  /// 当前壳层快照。
  final AdaptiveShellState state;

  /// 位于壳内时返回，否则 null。
  static AdaptiveShellState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdaptiveShellScope>()
        ?.state;
  }

  /// 读取壳层状态；不在壳内时 assert。
  static AdaptiveShellState of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'AdaptiveShellState not found in context');
    return scope!;
  }

  /// 下标、宽度或断点变化时通知（rail / 栏数）。
  @override
  bool updateShouldNotify(AdaptiveShellScope oldWidget) {
    return state.currentIndex != oldWidget.state.currentIndex ||
        state.width != oldWidget.state.width ||
        state.breakpoints != oldWidget.state.breakpoints;
  }
}
