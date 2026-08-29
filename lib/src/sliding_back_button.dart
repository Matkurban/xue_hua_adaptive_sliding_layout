import 'package:flutter/material.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_actions.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_window_scope.dart';

/// 仅在滑动栈顶（最右栏）且可出栈时显示的返回按钮。
///
/// 用 [SlidingPaneScope.showBack] 决定是否绘制；默认调用 [SlidingActions.pop]。
class SlidingBackButton extends StatelessWidget {
  /// [onPressed] 缺省为 [SlidingActions.pop]，再退到 [SlidingWindowController.pop]。
  const SlidingBackButton({super.key, this.onPressed});

  /// 覆盖默认出栈。为 null 时走 [SlidingActions] 或当前 Tab 的 controller。
  final VoidCallback? onPressed;

  /// 非栈顶或根页时返回 [SizedBox.shrink]，避免左栏也出现返回。
  @override
  Widget build(BuildContext context) {
    final pane = SlidingPaneScope.maybeOf(context);
    if (pane == null || !pane.showBack) {
      return const SizedBox.shrink();
    }
    return BackButton(
      onPressed:
          onPressed ??
          () {
            final actions = SlidingActions.maybeOf(context);
            if (actions != null) {
              actions.pop();
              return;
            }
            SlidingWindowScope.maybeOf(context)?.controller.pop();
          },
    );
  }
}
