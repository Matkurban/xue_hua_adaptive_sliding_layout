import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_actions.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_page_title.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_window_controller.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_window_page.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_window_scope.dart';

/// 水平滑动视口：始终展示栈顶最后 [visibleCount] 栏。
///
/// [visibleCount] 为 2 时可用分割条拖动左栏比例，夹在
/// [minLeftPaneFraction] 与 `1 - [minRightPaneFraction]` 之间。
class SlidingWindowViewport extends StatefulWidget {
  /// [controller] 与 [visibleCount] 必填；分割条参数可与 [MultiColumnScaffold] 对齐。
  const SlidingWindowViewport({
    super.key,
    required this.controller,
    required this.visibleCount,
    this.placeholder,
    this.leftPaneFraction = defaultLeftPaneFraction,
    this.minLeftPaneFraction = defaultMinLeftPaneFraction,
    this.minRightPaneFraction = defaultMinRightPaneFraction,
    this.onLeftPaneFractionChanged,
    this.resizeLeftPane,
  });

  /// 未指定时左栏占一半视口。
  static const double defaultLeftPaneFraction = 0.5;

  /// 左栏默认最小 30%。
  static const double defaultMinLeftPaneFraction = 0.3;

  /// 右栏默认最小 30%。
  static const double defaultMinRightPaneFraction = 0.3;

  /// 分割条命中区域的测试 Key。
  static const Key resizeHandleKey = Key('pane-resize-handle');

  /// 当前可见左栏的测试标记。挂在不包页面的兄弟上，换栏时不卸 [Navigator]。
  static const Key visibleLeftPaneKey = Key('sliding-visible-left');

  /// 当前可见右栏（或空占位）的测试标记。
  static const Key visibleRightPaneKey = Key('sliding-visible-right');

  /// 要绘制的栈。
  final SlidingWindowController controller;

  /// 同时可见的栏数，小于 1 时按 1 处理。
  final int visibleCount;

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
  State<SlidingWindowViewport> createState() => _SlidingWindowViewportState();
}

/// 订阅栈变化，并在双栏时用全局指针路由驱动分割条。
class _SlidingWindowViewportState extends State<SlidingWindowViewport> {
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

  /// 用构造时的比例初始化 [_fraction]。
  @override
  void initState() {
    super.initState();
    _fraction = _clamp(widget.leftPaneFraction);
  }

  /// 非拖拽时同步宿主比例与夹取上下限。
  @override
  void didUpdateWidget(covariant SlidingWindowViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragging) return;
    if (widget.leftPaneFraction != oldWidget.leftPaneFraction ||
        widget.minLeftPaneFraction != oldWidget.minLeftPaneFraction ||
        widget.minRightPaneFraction != oldWidget.minRightPaneFraction) {
      _fraction = _clamp(widget.leftPaneFraction);
    }
  }

  /// 卸掉全局指针路由，避免泄漏。
  @override
  void dispose() {
    _stopGlobalRoute();
    super.dispose();
  }

  /// 按当前 widget 的 min 夹取。
  double _clamp(double fraction) {
    return SlidingWindowViewport.clampLeftPaneFraction(
      fraction,
      minLeftPaneFraction: widget.minLeftPaneFraction,
      minRightPaneFraction: widget.minRightPaneFraction,
    );
  }

  /// 开始拖：记下 pointer、挂全局路由、立刻按当前位置改比例。
  void _onHandlePointerDown(PointerDownEvent event) {
    _activePointer = event.pointer;
    _dragging = true;
    if (!_listeningGlobal) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onGlobalPointer);
      _listeningGlobal = true;
    }
    _applyGlobalPosition(event.position);
  }

  /// 只处理当前 [_activePointer] 的 move / up / cancel。
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

  /// 用视口绝对坐标更新 [_fraction]，不累加 delta。
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

  /// 松手：停全局路由，并只在此时回调宿主。
  void _endDrag() {
    _stopGlobalRoute();
    if (!_dragging) return;
    _dragging = false;
    widget.onLeftPaneFractionChanged?.call(_fraction);
  }

  /// 移除 pointerRouter 并清空活动 pointer。
  void _stopGlobalRoute() {
    if (!_listeningGlobal) return;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onGlobalPointer);
    _listeningGlobal = false;
    _activePointer = null;
  }

  /// 宽度非法时收成空；双栏时叠分割条。
  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final pages = widget.controller.pages.value;
        return LayoutBuilder(
          builder: (context, constraints) {
            final count = widget.visibleCount < 1 ? 1 : widget.visibleCount;
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            if (!width.isFinite ||
                width <= 0 ||
                !height.isFinite ||
                height <= 0) {
              return const SizedBox.shrink();
            }
            final leftPaneWidth = count == 2 ? width * _fraction : width;
            final rightPaneWidth = count == 2 ? width - leftPaneWidth : width;
            final showHandle =
                (widget.resizeLeftPane ?? count == 2) && count == 2;
            return Stack(
              key: _viewportKey,
              clipBehavior: Clip.hardEdge,
              children: [
                _SlidingWindowStrip(
                  pages: pages,
                  visibleCount: count,
                  leftPaneWidth: leftPaneWidth,
                  rightPaneWidth: rightPaneWidth,
                  viewportHeight: height,
                  decoratePanes: count == 2,
                  placeholder:
                      widget.placeholder ?? const _SlidingPlaceholder(),
                ),
                if (showHandle)
                  Positioned(
                    left: leftPaneWidth - _PaneResizeHandle.hitExtent / 2,
                    top: 0,
                    bottom: 0,
                    width: _PaneResizeHandle.hitExtent,
                    child: _PaneResizeHandle(
                      onPointerDown: _onHandlePointerDown,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 双栏中间的拖动手柄：视觉 2px，命中宽度 [hitExtent]。
class _PaneResizeHandle extends StatelessWidget {
  const _PaneResizeHandle({required this.onPointerDown});

  /// 命中条宽度，大于可见线以便容易抓住。
  static const double hitExtent = 44;

  /// 按下后交给视口挂全局指针路由。
  final ValueChanged<PointerDownEvent> onPointerDown;

  /// 列向 resize 光标 + 半透明竖线。
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline.withValues(alpha: 0.55);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: Listener(
        key: SlidingWindowViewport.resizeHandleKey,
        behavior: HitTestBehavior.translucent,
        onPointerDown: onPointerDown,
        child: SizedBox.expand(
          child: Center(
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
class _SlidingWindowStrip extends StatefulWidget {
  const _SlidingWindowStrip({
    required this.pages,
    required this.visibleCount,
    required this.leftPaneWidth,
    required this.rightPaneWidth,
    required this.viewportHeight,
    required this.decoratePanes,
    required this.placeholder,
  });

  /// 完整栈，不只是可见页。
  final List<SlidingWindowPage> pages;

  /// 视口同时露出的栏数。
  final int visibleCount;

  /// 左栏（及滑出屏外的旧栏）宽度。
  final double leftPaneWidth;

  /// 最右可见栏宽度。
  final double rightPaneWidth;

  /// 视口高度，条带与各栏对齐。
  final double viewportHeight;

  /// 双栏时用卡片壳；单栏只用细分割线。
  final bool decoratePanes;

  /// 深度不足时填右栏。
  final Widget placeholder;

  @override
  State<_SlidingWindowStrip> createState() => _SlidingWindowStripState();
}

/// 用 [AnimationController] 在旧偏移与 [_targetOffset] 之间插值。
class _SlidingWindowStripState extends State<_SlidingWindowStrip>
    with SingleTickerProviderStateMixin {
  /// 深度变化时的滑动时长。
  static const Duration _duration = Duration(milliseconds: 280);

  /// 滑出曲线。
  static const Curve _curve = Curves.easeOutCubic;

  /// 驱动 [_curved]。
  late final AnimationController _controller;

  /// 施加 [_curve] 后的 0～1。
  late final CurvedAnimation _curved;

  /// 本段动画起点偏移。
  double _fromOffset = 0;

  /// 本段动画终点偏移。
  double _toOffset = 0;

  /// 无动画，[_toOffset] 对准当前栈。
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _curved = CurvedAnimation(parent: _controller, curve: _curve);
    _toOffset = _targetOffset(widget);
    _fromOffset = _toOffset;
  }

  /// 仅宽度变则跳到新偏移；深度变则从当前插值位置接着滑。
  @override
  void didUpdateWidget(covariant _SlidingWindowStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _targetOffset(widget);
    final widthChanged =
        oldWidget.leftPaneWidth != widget.leftPaneWidth ||
        oldWidget.rightPaneWidth != widget.rightPaneWidth;
    final depthChanged = oldWidget.pages.length != widget.pages.length;
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

  /// 让最后 [visibleCount] 栏落在视口内：`start * leftPaneWidth`。
  double _targetOffset(_SlidingWindowStrip w) {
    final start = math.max(0, w.pages.length - w.visibleCount);
    return start * w.leftPaneWidth;
  }

  /// 最右可见栏用 [rightPaneWidth]，其余用 [leftPaneWidth]。
  double _paneWidth(_SlidingWindowStrip w, int index) {
    if (w.visibleCount < 2) return w.leftPaneWidth;
    final start = math.max(0, w.pages.length - w.visibleCount);
    if (index == start + 1) return w.rightPaneWidth;
    return w.leftPaneWidth;
  }

  /// 释放动画资源。
  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// OverflowBox 必须包在 Transform 外，否则右栏命中会落到裁剪盒外。
  @override
  Widget build(BuildContext context) {
    final pages = widget.pages;
    final visibleCount = widget.visibleCount;
    final start = math.max(0, pages.length - visibleCount);
    final colorScheme = Theme.of(context).colorScheme;

    var stripWidth = 0.0;
    for (var i = 0; i < pages.length; i++) {
      stripWidth += _paneWidth(widget, i);
    }
    if (pages.length < visibleCount) {
      stripWidth += widget.rightPaneWidth;
    }
    // OverflowBox 必须包在 Transform 外：自身尺寸是视口，contains 用视口坐标；
    // Transform 再把点击映射到左移后的第三栏。反之右栏命中会落到 OverflowBox 尺寸外。
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
              for (var i = 0; i < pages.length; i++)
                _SlidingPane(
                  page: pages[i],
                  index: i,
                  depth: pages.length,
                  width: _paneWidth(widget, i),
                  height: widget.viewportHeight,
                  ticking: i >= start,
                  decorate: widget.decoratePanes,
                  showDivider: !widget.decoratePanes && i > 0,
                  dividerColor: colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                  layoutKey: visibleCount >= 2 && i == start
                      ? SlidingWindowViewport.visibleLeftPaneKey
                      : visibleCount >= 2 && i == start + 1
                      ? SlidingWindowViewport.visibleRightPaneKey
                      : null,
                ),
              if (pages.length < visibleCount)
                SizedBox(
                  key: visibleCount >= 2
                      ? SlidingWindowViewport.visibleRightPaneKey
                      : null,
                  width: widget.rightPaneWidth,
                  height: widget.viewportHeight,
                  child: widget.decoratePanes
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

/// 单栏：屏外停 ticker / 焦点 / 命中；可见栏包 [SlidingPaneScope] 与 [_PaneNavigator]。
class _SlidingPane extends StatelessWidget {
  const _SlidingPane({
    required this.page,
    required this.index,
    required this.depth,
    required this.width,
    required this.height,
    required this.ticking,
    required this.decorate,
    required this.showDivider,
    required this.dividerColor,
    this.layoutKey,
  });

  /// 本栏对应的栈页。
  final SlidingWindowPage page;

  /// 栈下标，写入 [SlidingPaneScope]。
  final int index;

  /// 当前深度，写入 [SlidingPaneScope]。
  final int depth;

  /// 栏宽。
  final double width;

  /// 栏高。
  final double height;

  /// 是否为可见栏（可见才走动画与命中）。
  final bool ticking;

  /// 是否套卡片壳。
  final bool decorate;

  /// 单栏模式下是否画左边线。
  final bool showDivider;

  /// [showDivider] 时的边线色。
  final Color dividerColor;

  /// 可见左/右栏的测试标记 Key。只挂在不包 [Navigator] 的兄弟上，
  /// 避免栏位切换时卸掉页面 State。
  final Key? layoutKey;

  /// 屏外栏 IgnorePointer + ExcludeFocus，避免点到滑走的页。
  @override
  Widget build(BuildContext context) {
    final pane = TickerMode(
      enabled: ticking,
      child: ExcludeFocus(
        excluding: !ticking,
        child: IgnorePointer(
          ignoring: !ticking,
          child: PageStorage(
            bucket: PageStorage.of(context),
            child: KeyedSubtree(
              key: PageStorageKey<LocalKey>(page.key),
              child: _PaneNavigator(page: page),
            ),
          ),
        ),
      ),
    );
    final decorated = decorate
        ? _PaneCardShell(child: pane)
        : DecoratedBox(
            decoration: BoxDecoration(
              border: showDivider
                  ? Border(left: BorderSide(color: dividerColor))
                  : null,
            ),
            child: pane,
          );
    return SlidingPaneScope(
      index: index,
      depth: depth,
      child: KeyedSubtree(
        key: page.key,
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

/// 双栏时每栏外圈的圆角卡片。
class _PaneCardShell extends StatelessWidget {
  const _PaneCardShell({required this.child});

  /// 栏内 Navigator 子树。
  final Widget child;

  /// 8px 边距 + elevation 2 的 surface 卡片。
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

/// 栏内独立 [Navigator]，让栏内路由 / Overlay 不冒到隔壁栏。
class _PaneNavigator extends StatelessWidget {
  const _PaneNavigator({required this.page});

  /// 用 [SlidingWindowPage.builder] 作为唯一路由。
  final SlidingWindowPage page;

  /// 包 [_SlidingTitleBinder] 与 [_SlidingDismissalBinder]。
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (routeContext) {
            return _SlidingTitleBinder(
              page: page,
              child: _SlidingDismissalBinder(child: page.builder(routeContext)),
            );
          },
        );
      },
    );
  }
}

/// 向子树提供 [SlidingPageTitle]，并在首帧从 AppBar.title 同步面包屑。
class _SlidingTitleBinder extends StatefulWidget {
  const _SlidingTitleBinder({required this.page, required this.child});

  /// 要写入 title 的栈页。
  final SlidingWindowPage page;

  /// 宿主页面。
  final Widget child;

  @override
  State<_SlidingTitleBinder> createState() => _SlidingTitleBinderState();
}

/// 首帧爬 [AppBar.title] 的 Text，覆盖入栈时的 humanize 标题。
class _SlidingTitleBinderState extends State<_SlidingTitleBinder> {
  /// 排到帧末再刮标题，此时 AppBar 已挂上。
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrapeAppBarTitle());
  }

  /// 找到非空标题则直接写 [SlidingWindowPage.title]。
  void _scrapeAppBarTitle() {
    if (!mounted) return;
    final text = _appBarTitleText(context);
    if (text != null && text.isNotEmpty) {
      widget.page.title.value = text;
    }
  }

  /// 深度优先找到第一个 [AppBar]，再取其 title 文本。
  String? _appBarTitleText(BuildContext context) {
    String? result;
    void visit(Element element) {
      if (result != null) return;
      final current = element.widget;
      if (current is AppBar && current.title != null) {
        result = _firstTextUnderTitle(element, current.title!);
        return;
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return result;
  }

  /// [titleWidget] 本身是 [Text] 则直接取；否则在其子树找第一段非空文本。
  String? _firstTextUnderTitle(Element appBarElement, Widget titleWidget) {
    if (titleWidget is Text) {
      return titleWidget.data ?? titleWidget.textSpan?.toPlainText();
    }
    Element? titleElement;
    void findTitle(Element element) {
      if (titleElement != null) return;
      if (identical(element.widget, titleWidget)) {
        titleElement = element;
        return;
      }
      element.visitChildren(findTitle);
    }

    appBarElement.visitChildren(findTitle);
    final root = titleElement;
    if (root == null) return null;
    String? text;
    void findText(Element element) {
      if (text != null) return;
      if (element.widget is Text) {
        final label = element.widget as Text;
        final data = label.data ?? label.textSpan?.toPlainText();
        if (data != null && data.isNotEmpty) {
          text = data;
          return;
        }
      }
      element.visitChildren(findText);
    }

    findText(root);
    return text;
  }

  /// 包一层 [SlidingPageTitle] 给页面 [report]。
  @override
  Widget build(BuildContext context) {
    return SlidingPageTitle(page: widget.page, child: widget.child);
  }
}

/// 仅栈顶栏向内部 [ModalRoute] 注册 [LocalHistoryEntry]，默认 AppBar 才有返回。
///
/// 这不是 [PopScope]：滑动栈 pop 走本 entry 的 onRemove → [SlidingActions.pop]。
class _SlidingDismissalBinder extends StatefulWidget {
  const _SlidingDismissalBinder({required this.child});

  /// 栏内页面。
  final Widget child;

  @override
  State<_SlidingDismissalBinder> createState() =>
      _SlidingDismissalBinderState();
}

/// 随 [SlidingPaneScope.showBack] 挂上 / 卸下 [LocalHistoryEntry]。
class _SlidingDismissalBinderState extends State<_SlidingDismissalBinder> {
  /// 当前挂在 [_route] 上的 entry；非栈顶时为 null。
  LocalHistoryEntry? _entry;

  /// entry 所在的栏内 ModalRoute。
  ModalRoute<dynamic>? _route;

  /// false 时卸 entry 不触发滑动栈 pop（例如本栏不再是栈顶）。
  bool _popOnRemove = true;

  /// 是否已跑过第一次 [didChangeDependencies]（区分首挂与 pop 后重回栈顶）。
  bool _dependenciesInitialized = false;

  /// 缓存的出栈回调，避免 onRemove 时 context 已失效。
  VoidCallback? _pop;

  /// 按 [showBack] 同步挂/卸 entry。重回栈顶须帧末再挂，AppBar 才能收到 canPop。
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachePop();
    final showBack = SlidingPaneScope.maybeOf(context)?.showBack ?? false;
    if (!showBack) {
      _detachWithoutPop();
    } else if (!_dependenciesInitialized) {
      // 首次挂载发生在栏内 AppBar 首帧之前，同步挂 entry 才能首帧就显示返回。
      _attach();
    } else if (_entry == null) {
      // pop 后重新成为栈顶时正处于 build 阶段；框架会跳过 changedInternalState 的
      // setState，必须推迟到帧末挂载，AppBar 才能收到 canPop 变更。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _entry != null) return;
        final scope = context.getInheritedWidgetOfExactType<SlidingPaneScope>();
        if (scope != null && scope.showBack) _attach();
      });
    }
    _dependenciesInitialized = true;
  }

  /// 优先 [SlidingActions.pop]，否则当前 Tab 的 controller.pop。
  void _cachePop() {
    final actions = SlidingActions.maybeOf(context);
    if (actions != null) {
      _pop = actions.pop;
      return;
    }
    final controller = SlidingWindowScope.maybeOf(context)?.controller;
    _pop = controller == null ? null : () => controller.pop();
  }

  /// 卸 entry 且不 pop（组件销毁）。
  @override
  void dispose() {
    _detachWithoutPop();
    super.dispose();
  }

  /// 向当前 [ModalRoute] 加 [LocalHistoryEntry]，让默认 AppBar 显示返回。
  void _attach() {
    if (_entry != null) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    _route = route;
    _popOnRemove = true;
    _entry = LocalHistoryEntry(onRemove: _onRemove);
    route.addLocalHistoryEntry(_entry!);
  }

  /// 系统/AppBar pop 掉 entry 时，若 [_popOnRemove] 则弹出滑动栈。
  void _onRemove() {
    _entry = null;
    _route = null;
    if (_popOnRemove) {
      _pop?.call();
    }
  }

  /// 主动卸 entry，不触发滑动栈 pop。
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

  /// 透传子树，本身不占布局。
  @override
  Widget build(BuildContext context) => widget.child;
}

/// 双栏且深度为 1 时右栏的默认空态。
class _SlidingPlaceholder extends StatelessWidget {
  const _SlidingPlaceholder();

  /// 浅底 + 居中 web_asset 图标。
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
