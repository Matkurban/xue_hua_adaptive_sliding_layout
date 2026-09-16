import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/pane_scope.dart';

/// 画出整栈标题；点击非最后一项则回调 [onSelect]，通常接到
/// `router.popUntil((m) => m.pageKey == pane.key)`。
class AdaptiveBreadcrumbs extends StatelessWidget {
  /// [panes] 为当前分支完整栈（不只是可见栏）。
  const AdaptiveBreadcrumbs({
    super.key,
    required this.panes,
    required this.onSelect,
  });

  /// 当前分支的栏。
  final List<SlidingPane> panes;

  /// 点击非最后一项时传入被点中的栏。
  final ValueChanged<SlidingPane> onSelect;

  /// 空标题页不画；最后一项不可点。
  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final visible = [
          for (final pane in panes)
            if (pane.title.value.isNotEmpty) pane,
        ];
        if (visible.isEmpty) return const SizedBox.shrink();
        final colorScheme = Theme.of(context).colorScheme;
        return Material(
          color: colorScheme.surfaceContainerLow,
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: visible.length,
              separatorBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: colorScheme.outline,
                  ),
                );
              },
              itemBuilder: (context, index) {
                final pane = visible[index];
                final isLast = index == visible.length - 1;
                return InkWell(
                  onTap: isLast ? null : () => onSelect(pane),
                  hoverColor: colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Text(
                        pane.title.value,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: isLast
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: isLast
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
