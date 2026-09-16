import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/pane_scope.dart';

/// 自定义单个面包屑。最后一项的 [onTap] 为 null。
typedef AdaptiveBreadcrumbItemBuilder =
    Widget Function(
      BuildContext context,
      SlidingPane pane,
      bool isLast,
      VoidCallback? onTap,
    );

/// 自定义面包屑分隔符。[index] 为左侧项下标。
typedef AdaptiveBreadcrumbSeparatorBuilder =
    Widget Function(BuildContext context, int index);

/// 整条面包屑的替换工厂。仍由壳在 [showBreadcrumbs] 为 true 时调用。
typedef AdaptiveBreadcrumbsBuilder =
    Widget Function(
      BuildContext context,
      List<SlidingPane> panes,
      ValueChanged<SlidingPane> onSelect,
    );

/// 画出整栈标题；点击非最后一项则回调 [onSelect]，通常接到
/// `router.popUntil((m) => m.pageKey == pane.key)`。
class AdaptiveBreadcrumbs extends StatelessWidget {
  /// [panes] 为当前分支完整栈（不只是可见栏）。
  const AdaptiveBreadcrumbs({
    super.key,
    required this.panes,
    required this.onSelect,
    this.height = 32,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.backgroundColor,
    this.itemBuilder,
    this.separatorBuilder,
  });

  /// 当前分支的栏。
  final List<SlidingPane> panes;

  /// 点击非最后一项时传入被点中的栏。
  final ValueChanged<SlidingPane> onSelect;

  /// 条带高度。
  final double height;

  /// 水平内边距。
  final EdgeInsetsGeometry padding;

  /// 底色；缺省 [ColorScheme.surfaceContainerLow]。
  final Color? backgroundColor;

  /// 替换默认 InkWell + Text。
  final AdaptiveBreadcrumbItemBuilder? itemBuilder;

  /// 替换默认 chevron。
  final AdaptiveBreadcrumbSeparatorBuilder? separatorBuilder;

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
          color: backgroundColor ?? colorScheme.surfaceContainerLow,
          child: SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: padding,
              itemCount: visible.length,
              separatorBuilder: (context, index) {
                return separatorBuilder?.call(context, index) ??
                    Padding(
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
                final onTap = isLast ? null : () => onSelect(pane);
                return itemBuilder?.call(context, pane, isLast, onTap) ??
                    InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
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
