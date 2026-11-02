import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/pane_scope.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/widgets/pane_resize_handle.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/widgets/sliding_pane_strip.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/widgets/sliding_placeholder.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_shell_route.dart';

/// 水平滑动视口：始终展示栈顶最后 [visibleCount] 栏。
///
/// [visibleCount] 为 2 时可用分割条拖动左栏比例，夹在
/// [minLeftPaneFraction] 与 `1 - [minRightPaneFraction]` 之间。
class SlidingPaneViewport extends StatefulWidget {
  /// [panes] 与 [visibleCount] 必填；[onPop] 供栏内 AppBar 返回调用。
  const SlidingPaneViewport({
    super.key,
    required this.panes,
    required this.visibleCount,
    this.onPop,
    this.placeholder,
    this.leftPaneFraction = defaultLeftPaneFraction,
    this.minLeftPaneFraction = defaultMinLeftPaneFraction,
    this.minRightPaneFraction = defaultMinRightPaneFraction,
    this.onLeftPaneFractionChanged,
    this.resizeLeftPane,
    this.slideDuration = defaultSlideDuration,
    this.slideCurve = defaultSlideCurve,
    this.paneBuilder,
    required this.resizeHandleWidth,
    this.resizeHandleMargin,
    this.resizeHandleBuilder,
  });

  /// 未指定时左栏占视口的 40%。
  static const double defaultLeftPaneFraction = 0.4;

  /// 左栏默认最小 35%。
  static const double defaultMinLeftPaneFraction = 0.35;

  /// 右栏默认最小 35%。
  static const double defaultMinRightPaneFraction = 0.35;

  /// 栏位平移动画默认时长。
  static const Duration defaultSlideDuration = Duration(milliseconds: 280);

  /// 栏位平移动画默认曲线。
  static const Curve defaultSlideCurve = Curves.easeOutCubic;

  /// 分割条命中区域的测试 Key。
  static const Key resizeHandleKey = Key('pane-resize-handle');

  /// 当前可见左栏的测试标记。挂在不包页面的兄弟上，换栏时不卸 [Navigator]。
  static const Key visibleLeftPaneKey = Key('sliding-visible-left');

  /// 当前可见右栏（或空占位）的测试标记。
  static const Key visibleRightPaneKey = Key('sliding-visible-right');

  /// 完整栈，不只是可见栏。
  final List<SlidingPane> panes;

  /// 同时可见的栏数，小于 1 时按 1 处理。
  final int visibleCount;

  /// 栈顶栏 AppBar 返回 / LocalHistoryEntry 触发。为 null 时不注册返回条目。
  final VoidCallback? onPop;

  /// 深度不足 [visibleCount] 时，空出来的右栏内容。
  final Widget? placeholder;

  /// 左栏占视口宽度的比例（双栏时）。未提供 [onLeftPaneFractionChanged] 时由本组件保存。
  final double leftPaneFraction;

  /// 左栏最小比例。
  final double minLeftPaneFraction;

  /// 右栏最小比例（决定左栏上限）。
  final double minRightPaneFraction;

  /// 分割条拖完松手时回调。拖拽过程中用视口绝对坐标本地更新，不通知宿主。
  final ValueChanged<double>? onLeftPaneFractionChanged;

  /// 是否显示分割条。缺省在 [visibleCount] 为 2 时开启。
  final bool? resizeLeftPane;

  /// 栏位平移动画时长。
  final Duration slideDuration;

  /// 栏位平移动画曲线。
  final Curve slideCurve;

  /// 包每一栏；[index] 等于 [panes.length] 时是右侧占位槽。
  /// 缺省双栏用卡片、单栏平铺。
  final SlidingPaneFrameBuilder? paneBuilder;

  /// 分隔条的宽度。
  final double resizeHandleWidth;

  /// 分隔条的外边距，实现显示的是：宽度 - 左右外边距的和。
  final EdgeInsets? resizeHandleMargin;

  /// 只换分割条视觉；Listener、光标、命中区仍由包负责。
  final ResizeHandleWidgetBuilder? resizeHandleBuilder;

  /// 把 [fraction] 夹到 [minLeftPaneFraction] 与 `1 - minRightPaneFraction` 之间。
  /// 区间倒置时取中点，避免 NaN。
  static double clampLeftPaneFraction(
    double fraction, {
    double minLeftPaneFraction = defaultMinLeftPaneFraction,
    double minRightPaneFraction = defaultMinRightPaneFraction,
  }) {
    final minLeft = minLeftPaneFraction.clamp(0.0, 1.0);
    final maxLeft = (1.0 - minRightPaneFraction.clamp(0.0, 1.0)).clamp(
      0.0,
      1.0,
    );
    if (maxLeft < minLeft) {
      return ((minLeft + maxLeft) / 2).clamp(0.0, 1.0);
    }
    return fraction.clamp(minLeft, maxLeft);
  }

  @override
  State<SlidingPaneViewport> createState() => _SlidingPaneViewportState();
}

/// 双栏时用全局指针路由驱动分割条。
class _SlidingPaneViewportState extends State<SlidingPaneViewport> {
  /// 供 `globalToLocal` 把指针换成视口内比例。
  final GlobalKey _viewportKey = GlobalKey();

  /// 当前左栏比例（拖拽中为本地值）。
  late double _fraction;

  /// 是否正在拖分割条。为 true 时忽略外部 [leftPaneFraction] 回写。
  bool _dragging = false;

  /// 当前拖拽的 pointer id；其它指针忽略。
  int? _activePointer;

  /// 是否已挂上 [GestureBinding.pointerRouter] 全局路由。
  bool _listeningGlobal = false;

  @override
  void initState() {
    super.initState();
    _fraction = _clamp(widget.leftPaneFraction);
  }

  @override
  void didUpdateWidget(covariant SlidingPaneViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragging) return;
    if (widget.leftPaneFraction != oldWidget.leftPaneFraction ||
        widget.minLeftPaneFraction != oldWidget.minLeftPaneFraction ||
        widget.minRightPaneFraction != oldWidget.minRightPaneFraction) {
      _fraction = _clamp(widget.leftPaneFraction);
    }
  }

  @override
  void dispose() {
    _stopGlobalRoute();
    super.dispose();
  }

  double _clamp(double fraction) {
    return SlidingPaneViewport.clampLeftPaneFraction(
      fraction,
      minLeftPaneFraction: widget.minLeftPaneFraction,
      minRightPaneFraction: widget.minRightPaneFraction,
    );
  }

  void _onHandlePointerDown(PointerDownEvent event) {
    _activePointer = event.pointer;
    _dragging = true;
    if (!_listeningGlobal) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onGlobalPointer);
      _listeningGlobal = true;
    }
    _applyGlobalPosition(event.position);
  }

  void _onGlobalPointer(PointerEvent event) {
    if (event.pointer != _activePointer) return;
    if (event is PointerMoveEvent) {
      _applyGlobalPosition(event.position);
      return;
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _applyGlobalPosition(event.position);
      _endDrag();
    }
  }

  void _applyGlobalPosition(Offset global) {
    if (!mounted) return;
    final box = _viewportKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final width = box.size.width;
    if (width <= 0) return;
    final next = _clamp(box.globalToLocal(global).dx / width);
    if (next == _fraction) return;
    setState(() => _fraction = next);
  }

  void _endDrag() {
    _stopGlobalRoute();
    if (!_dragging) return;
    _dragging = false;
    widget.onLeftPaneFractionChanged?.call(_fraction);
  }

  void _stopGlobalRoute() {
    if (!_listeningGlobal) return;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onGlobalPointer);
    _listeningGlobal = false;
    _activePointer = null;
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.visibleCount < 1 ? 1 : widget.visibleCount;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (!width.isFinite || width <= 0 || !height.isFinite || height <= 0) {
          return const SizedBox.shrink();
        }
        final leftPaneWidth = count == 2 ? width * _fraction : width;
        final rightPaneWidth = count == 2 ? width - leftPaneWidth : width;
        final showHandle = (widget.resizeLeftPane ?? count == 2) && count == 2;
        return Stack(
          key: _viewportKey,
          clipBehavior: Clip.hardEdge,
          children: [
            SlidingPaneStrip(
              panes: widget.panes,
              visibleCount: count,
              leftPaneWidth: leftPaneWidth,
              rightPaneWidth: rightPaneWidth,
              viewportHeight: height,
              decoratePanes: count == 2,
              onPop: widget.onPop,
              placeholder: widget.placeholder ?? const SlidingPlaceholder(),
              slideDuration: widget.slideDuration,
              slideCurve: widget.slideCurve,
              paneBuilder: widget.paneBuilder,
            ),
            if (showHandle)
              Positioned(
                left: leftPaneWidth - widget.resizeHandleWidth / 2,
                top: 0,
                bottom: 0,
                width: widget.resizeHandleWidth,
                child: PaneResizeHandle(
                  onPointerDown: _onHandlePointerDown,
                  resizeHandleWidth: widget.resizeHandleWidth,
                  resizeHandleMargin: widget.resizeHandleMargin,
                  isDragging: _dragging,
                  builder: widget.resizeHandleBuilder,
                ),
              ),
            if (_dragging)
              const Positioned.fill(
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: SizedBox.expand(),
                ),
              ),
          ],
        );
      },
    );
  }
}
