import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/pane_scope.dart';

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
    this.resizeHandleBuilder,
  });

  /// 未指定时左栏占一半视口。
  static const double defaultLeftPaneFraction = 0.5;

  /// 左栏默认最小 30%。
  static const double defaultMinLeftPaneFraction = 0.3;

  /// 右栏默认最小 30%。
  static const double defaultMinRightPaneFraction = 0.3;

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

  /// 只换分割条视觉；Listener、光标、44px 命中区仍由包负责。
  final WidgetBuilder? resizeHandleBuilder;

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
            _SlidingPaneStrip(
              panes: widget.panes,
              visibleCount: count,
              leftPaneWidth: leftPaneWidth,
              rightPaneWidth: rightPaneWidth,
              viewportHeight: height,
              decoratePanes: count == 2,
              onPop: widget.onPop,
              placeholder: widget.placeholder ?? const _SlidingPlaceholder(),
              slideDuration: widget.slideDuration,
              slideCurve: widget.slideCurve,
              paneBuilder: widget.paneBuilder,
            ),
            if (showHandle)
              Positioned(
                left: leftPaneWidth - _PaneResizeHandle.hitExtent / 2,
                top: 0,
                bottom: 0,
                width: _PaneResizeHandle.hitExtent,
                child: _PaneResizeHandle(
                  onPointerDown: _onHandlePointerDown,
                  builder: widget.resizeHandleBuilder,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 双栏中间的拖动手柄：视觉 2px，命中宽度 [hitExtent]。
class _PaneResizeHandle extends StatelessWidget {
  const _PaneResizeHandle({required this.onPointerDown, this.builder});

  static const double hitExtent = 44;

  final ValueChanged<PointerDownEvent> onPointerDown;
  final WidgetBuilder? builder;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline.withValues(alpha: 0.55);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: Listener(
        key: SlidingPaneViewport.resizeHandleKey,
        behavior: HitTestBehavior.translucent,
        onPointerDown: onPointerDown,
        child: SizedBox.expand(
          child:
              builder?.call(context) ??
              Center(
                child: SizedBox(
                  width: 2,
                  height: double.infinity,
                  child: ColoredBox(color: color),
                ),
              ),
        ),
      ),
    );
  }
}

/// 整条水平页带：深度变化时平移动画，宽度变化时跳到目标偏移。
class _SlidingPaneStrip extends StatefulWidget {
  const _SlidingPaneStrip({
    required this.panes,
    required this.visibleCount,
    required this.leftPaneWidth,
    required this.rightPaneWidth,
    required this.viewportHeight,
    required this.decoratePanes,
    required this.placeholder,
    required this.onPop,
    required this.slideDuration,
    required this.slideCurve,
    this.paneBuilder,
  });

  final List<SlidingPane> panes;
  final int visibleCount;
  final double leftPaneWidth;
  final double rightPaneWidth;
  final double viewportHeight;
  final bool decoratePanes;
  final Widget placeholder;
  final VoidCallback? onPop;
  final Duration slideDuration;
  final Curve slideCurve;
  final SlidingPaneFrameBuilder? paneBuilder;

  @override
  State<_SlidingPaneStrip> createState() => _SlidingPaneStripState();
}

class _SlidingPaneStripState extends State<_SlidingPaneStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late CurvedAnimation _curved;
  double _fromOffset = 0;
  double _toOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.slideDuration,
    );
    _curved = CurvedAnimation(parent: _controller, curve: widget.slideCurve);
    _toOffset = _targetOffset(widget);
    _fromOffset = _toOffset;
  }

  @override
  void didUpdateWidget(covariant _SlidingPaneStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slideDuration != oldWidget.slideDuration) {
      _controller.duration = widget.slideDuration;
    }
    if (widget.slideCurve != oldWidget.slideCurve) {
      _curved.dispose();
      _curved = CurvedAnimation(parent: _controller, curve: widget.slideCurve);
    }
    final next = _targetOffset(widget);
    final widthChanged =
        oldWidget.leftPaneWidth != widget.leftPaneWidth ||
        oldWidget.rightPaneWidth != widget.rightPaneWidth;
    final depthChanged = oldWidget.panes.length != widget.panes.length;
    if (widthChanged && !depthChanged) {
      _fromOffset = next;
      _toOffset = next;
      _controller.value = 1;
      return;
    }
    if (next == _toOffset) return;
    final current = _fromOffset + (_toOffset - _fromOffset) * _curved.value;
    _fromOffset = current;
    _toOffset = next;
    _controller
      ..stop()
      ..forward(from: 0);
  }

  double _targetOffset(_SlidingPaneStrip w) {
    final start = math.max(0, w.panes.length - w.visibleCount);
    return start * w.leftPaneWidth;
  }

  double _paneWidth(_SlidingPaneStrip w, int index) {
    if (w.visibleCount < 2) return w.leftPaneWidth;
    final start = math.max(0, w.panes.length - w.visibleCount);
    if (index == start + 1) return w.rightPaneWidth;
    return w.leftPaneWidth;
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panes = widget.panes;
    final visibleCount = widget.visibleCount;
    final start = math.max(0, panes.length - visibleCount);
    final colorScheme = Theme.of(context).colorScheme;

    var stripWidth = 0.0;
    for (var i = 0; i < panes.length; i++) {
      stripWidth += _paneWidth(widget, i);
    }
    if (panes.length < visibleCount) {
      stripWidth += widget.rightPaneWidth;
    }
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: stripWidth,
        maxWidth: stripWidth,
        minHeight: widget.viewportHeight,
        maxHeight: widget.viewportHeight,
        child: AnimatedBuilder(
          animation: _curved,
          builder: (context, child) {
            final offset =
                _fromOffset + (_toOffset - _fromOffset) * _curved.value;
            return Transform.translate(
              offset: Offset(-offset, 0),
              child: child,
            );
          },
          child: Row(
            children: [
              for (var i = 0; i < panes.length; i++)
                _SlidingPaneFrame(
                  pane: panes[i],
                  index: i,
                  depth: panes.length,
                  width: _paneWidth(widget, i),
                  height: widget.viewportHeight,
                  ticking: i >= start,
                  decorate: widget.decoratePanes,
                  showDivider: !widget.decoratePanes && i > 0,
                  dividerColor: colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                  onPop: widget.onPop,
                  paneBuilder: widget.paneBuilder,
                  layoutKey: visibleCount >= 2 && i == start
                      ? SlidingPaneViewport.visibleLeftPaneKey
                      : visibleCount >= 2 && i == start + 1
                      ? SlidingPaneViewport.visibleRightPaneKey
                      : null,
                ),
              if (panes.length < visibleCount)
                SizedBox(
                  key: visibleCount >= 2
                      ? SlidingPaneViewport.visibleRightPaneKey
                      : null,
                  width: widget.rightPaneWidth,
                  height: widget.viewportHeight,
                  child: widget.paneBuilder != null
                      ? widget.paneBuilder!(
                          context,
                          panes.length,
                          widget.placeholder,
                        )
                      : widget.decoratePanes
                      ? _PaneCardShell(child: widget.placeholder)
                      : widget.placeholder,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 单栏：屏外停 ticker / 焦点 / 命中；可见栏包 [AdaptivePaneScope] 与栏内 Navigator。
class _SlidingPaneFrame extends StatelessWidget {
  const _SlidingPaneFrame({
    required this.pane,
    required this.index,
    required this.depth,
    required this.width,
    required this.height,
    required this.ticking,
    required this.decorate,
    required this.showDivider,
    required this.dividerColor,
    required this.onPop,
    this.layoutKey,
    this.paneBuilder,
  });

  final SlidingPane pane;
  final int index;
  final int depth;
  final double width;
  final double height;
  final bool ticking;
  final bool decorate;
  final bool showDivider;
  final Color dividerColor;
  final VoidCallback? onPop;
  final Key? layoutKey;
  final SlidingPaneFrameBuilder? paneBuilder;

  @override
  Widget build(BuildContext context) {
    final inner = TickerMode(
      enabled: ticking,
      child: ExcludeFocus(
        excluding: !ticking,
        child: IgnorePointer(
          ignoring: !ticking,
          child: PageStorage(
            bucket: PageStorage.of(context),
            child: KeyedSubtree(
              key: PageStorageKey<LocalKey>(pane.key),
              child: _PaneNavigator(pane: pane, onPop: onPop),
            ),
          ),
        ),
      ),
    );
    final decorated = paneBuilder != null
        ? paneBuilder!(context, index, inner)
        : decorate
        ? _PaneCardShell(child: inner)
        : DecoratedBox(
            decoration: BoxDecoration(
              border: showDivider
                  ? Border(left: BorderSide(color: dividerColor))
                  : null,
            ),
            child: inner,
          );
    return AdaptivePaneScope(
      index: index,
      depth: depth,
      title: pane.title,
      pop: onPop ?? () {},
      child: KeyedSubtree(
        key: pane.key,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              decorated,
              if (layoutKey != null)
                IgnorePointer(child: SizedBox.expand(key: layoutKey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaneCardShell extends StatelessWidget {
  const _PaneCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        elevation: 2,
        color: colorScheme.surface,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

/// 栏内独立 [Navigator]，让栏内 Overlay 不冒到隔壁栏。
class _PaneNavigator extends StatelessWidget {
  const _PaneNavigator({required this.pane, required this.onPop});

  final SlidingPane pane;
  final VoidCallback? onPop;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (routeContext) {
            return _SlidingDismissalBinder(onPop: onPop, child: pane.child);
          },
        );
      },
    );
  }
}

/// 仅栈顶栏向内部 [ModalRoute] 注册 [LocalHistoryEntry]，默认 AppBar 才有返回。
///
/// 滑动栈 pop 走本 entry 的 onRemove → [onPop]（通常是 [AdaptiveRouter.maybePop]）。
class _SlidingDismissalBinder extends StatefulWidget {
  const _SlidingDismissalBinder({required this.child, required this.onPop});

  final Widget child;
  final VoidCallback? onPop;

  @override
  State<_SlidingDismissalBinder> createState() =>
      _SlidingDismissalBinderState();
}

class _SlidingDismissalBinderState extends State<_SlidingDismissalBinder> {
  LocalHistoryEntry? _entry;
  ModalRoute<dynamic>? _route;
  bool _popOnRemove = true;
  bool _dependenciesInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final showBack = AdaptivePaneScope.maybeOf(context)?.showBack ?? false;
    if (!showBack) {
      _detachWithoutPop();
    } else if (!_dependenciesInitialized) {
      _attach();
    } else if (_entry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _entry != null) return;
        final scope = context
            .getInheritedWidgetOfExactType<AdaptivePaneScope>();
        if (scope != null && scope.showBack) _attach();
      });
    }
    _dependenciesInitialized = true;
  }

  @override
  void dispose() {
    _detachWithoutPop();
    super.dispose();
  }

  void _attach() {
    if (_entry != null) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    _route = route;
    _popOnRemove = true;
    _entry = LocalHistoryEntry(onRemove: _onRemove);
    route.addLocalHistoryEntry(_entry!);
  }

  void _onRemove() {
    _entry = null;
    _route = null;
    if (!_popOnRemove) return;
    final onPop = widget.onPop;
    if (onPop == null) return;
    onPop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _entry != null) return;
      final scope = context.getInheritedWidgetOfExactType<AdaptivePaneScope>();
      if (scope != null && scope.showBack) _attach();
    });
  }

  void _detachWithoutPop() {
    final entry = _entry;
    final route = _route;
    if (entry == null || route == null) {
      _entry = null;
      _route = null;
      _popOnRemove = true;
      return;
    }
    _popOnRemove = false;
    route.removeLocalHistoryEntry(entry);
    _entry = null;
    _route = null;
    _popOnRemove = true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SlidingPlaceholder extends StatelessWidget {
  const _SlidingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerLow,
      child: Center(
        child: Icon(
          Icons.web_asset_outlined,
          size: 48,
          color: colorScheme.outline,
        ),
      ),
    );
  }
}
