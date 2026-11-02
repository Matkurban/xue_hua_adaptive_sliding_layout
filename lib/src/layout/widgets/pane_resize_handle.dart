import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/sliding_pane_viewport.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_shell_route.dart';

/// 双栏中间的拖动手柄：视觉圆角条，命中宽度 [resizeHandleWidth]。
class PaneResizeHandle extends StatefulWidget {
  const PaneResizeHandle({
    super.key,
    required this.onPointerDown,
    this.isDragging = false,
    this.builder,
    this.resizeHandleMargin,
    required this.resizeHandleWidth,
  });

  final ValueChanged<PointerDownEvent> onPointerDown;
  final bool isDragging;
  final ResizeHandleWidgetBuilder? builder;
  final double resizeHandleWidth;
  final EdgeInsets? resizeHandleMargin;

  @override
  State<PaneResizeHandle> createState() => _PaneResizeHandleState();
}

class _PaneResizeHandleState extends State<PaneResizeHandle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 悬停中 或 拖拽中 均保持高亮色
    final isActive = _isHovered || widget.isDragging;
    final handleColor = isActive ? colorScheme.primary : colorScheme.surfaceDim;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Listener(
        key: SlidingPaneViewport.resizeHandleKey,
        behavior: HitTestBehavior.translucent,
        onPointerDown: widget.onPointerDown,
        child:
            widget.builder?.call(context, isActive) ??
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              height: double.infinity,
              width: widget.resizeHandleWidth,
              margin: widget.resizeHandleMargin,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: handleColor,
              ),
            ),
      ),
    );
  }
}
