import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_actions.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_window_controller.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_window_scope.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_window_viewport.dart';

/// 多栏壳层：可选左侧栏 + 滑动视口 + 面包屑 / Escape 返回。
///
/// 首次 build 调用 [SlidingWindowController.ensureRoot]。每个 Tab 放一个本组件，
/// 常用 [IndexedStack] 保活。
class MultiColumnScaffold extends StatefulWidget {
  /// [controller] / [root] / [rootName] / [visibleCount] 为接入所需的最小集合。
  const MultiColumnScaffold({
    super.key,
    required this.controller,
    required this.root,
    required this.rootName,
    required this.visibleCount,
    this.leading,
    this.showBreadcrumbs = false,
    this.onEscapePop,
    this.leftPaneFraction = SlidingWindowViewport.defaultLeftPaneFraction,
    this.minLeftPaneFraction = SlidingWindowViewport.defaultMinLeftPaneFraction,
    this.minRightPaneFraction =
        SlidingWindowViewport.defaultMinRightPaneFraction,
    this.onLeftPaneFractionChanged,
    this.resizeLeftPane,
  });

  /// 本 Tab 的滑动栈。
  final SlidingWindowController controller;

  /// 根页 Widget，写入 [ensureRoot] 的 builder。
  final Widget root;

  /// 根页在栈中的 [SlidingWindowPage.name]。
  final String rootName;

  /// 视口显示几栏（1 或 2），通常来自 [SlidingShell.visibleColumnCount]。
  final int visibleCount;

  /// 视口左侧的可选装饰（列表、内嵌 rail 等）。
  final Widget? leading;

  /// 为 true 时在视口上方画出整栈面包屑（不只是可见栏）。
  final bool showBreadcrumbs;

  /// 未聚焦输入框时按 Escape 的出栈回调；默认 [SlidingWindowController.pop]。
  /// 同时写入 [SlidingActions]，供视口 AppBar 返回与 [SlidingBackButton] 使用。
  final VoidCallback? onEscapePop;

  /// 双栏时左栏占视口宽度的比例。与 [onLeftPaneFractionChanged] 一起可受控（松手时回调）。
  final double leftPaneFraction;

  /// 左栏最小比例，默认 0.3。
  final double minLeftPaneFraction;

  /// 右栏最小比例，默认 0.3（左栏最大 0.7）。
  final double minRightPaneFraction;

  /// 分割条拖完松手时的新比例。不传则由视口自己保存。
  final ValueChanged<double>? onLeftPaneFractionChanged;

  /// 是否显示左栏分割条。缺省在 [visibleCount] 为 2 时开启。
  final bool? resizeLeftPane;

  @override
  State<MultiColumnScaffold> createState() => _MultiColumnScaffoldState();
}

/// 写入 scope / actions，并把 Escape 接到 [_pop]。
class _MultiColumnScaffoldState extends State<MultiColumnScaffold> {
  /// 首次挂载时 [ensureRoot]，保证栈至少有根页。
  @override
  void initState() {
    super.initState();
    widget.controller.ensureRoot(
      name: widget.rootName,
      builder: (_) => widget.root,
    );
  }

  /// 根名或根 Widget 更换时再次 [ensureRoot]（栈已有内容则仍忽略）。
  @override
  void didUpdateWidget(covariant MultiColumnScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rootName != widget.rootName ||
        oldWidget.root != widget.root) {
      widget.controller.ensureRoot(
        name: widget.rootName,
        builder: (_) => widget.root,
      );
    }
  }

  /// 宿主 [onEscapePop] 或直接 [SlidingWindowController.pop]。
  void _pop() {
    (widget.onEscapePop ?? widget.controller.pop).call();
  }

  /// 焦点在输入框或不能 pop 时忽略 Escape。
  void _onEscape() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus is EditableTextState) return;
    if (!widget.controller.canPop) return;
    _pop();
  }

  /// 注入 [SlidingWindowScope] 与 [SlidingActions]，可选面包屑 + 视口。
  @override
  Widget build(BuildContext context) {
    return SlidingWindowScope(
      controller: widget.controller,
      child: SlidingActions(
        pop: _pop,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): _onEscape,
          },
          child: Focus(
            canRequestFocus: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.leading != null) widget.leading!,
                Expanded(
                  child: Column(
                    children: [
                      if (widget.showBreadcrumbs)
                        _SlidingBreadcrumbs(controller: widget.controller),
                      Expanded(
                        child: SlidingWindowViewport(
                          controller: widget.controller,
                          visibleCount: widget.visibleCount,
                          leftPaneFraction: widget.leftPaneFraction,
                          minLeftPaneFraction: widget.minLeftPaneFraction,
                          minRightPaneFraction: widget.minRightPaneFraction,
                          onLeftPaneFractionChanged:
                              widget.onLeftPaneFractionChanged,
                          resizeLeftPane: widget.resizeLeftPane,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 画出整栈标题；点击非最后一项则 [SlidingWindowController.popUntil] 到该页。
class _SlidingBreadcrumbs extends StatelessWidget {
  const _SlidingBreadcrumbs({required this.controller});

  /// 订阅 [SlidingWindowController.pages] 与各页 title。
  final SlidingWindowController controller;

  /// 空标题页不画；最后一项不可点。
  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final pages = controller.pages.value
            .where((page) => page.title.value.isNotEmpty)
            .toList();
        if (pages.isEmpty) return const SizedBox.shrink();
        final colorScheme = Theme.of(context).colorScheme;
        return Material(
          color: colorScheme.surfaceContainerLow,
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: pages.length,
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
                final page = pages[index];
                final isLast = index == pages.length - 1;
                return InkWell(
                  onTap: isLast
                      ? null
                      : () =>
                            controller.popUntil((item) => item.key == page.key),
                  hoverColor: colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Text(
                        page.title.value,
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
