import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/pane_scope.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/sliding_pane_viewport.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/widgets/pane_card_shell.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/widgets/sliding_pane_frame.dart';

/// 整条水平页带：深度变化时平移动画，宽度变化时跳到目标偏移。
class SlidingPaneStrip extends StatefulWidget {
  const SlidingPaneStrip({
    super.key,
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
  State<SlidingPaneStrip> createState() => _SlidingPaneStripState();
}

class _SlidingPaneStripState extends State<SlidingPaneStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late CurvedAnimation _curved;
  late final ValueNotifier<bool> _settledNotifier;
  double _fromOffset = 0;
  double _toOffset = 0;

  void _onSlideStatusChanged(AnimationStatus _) {
    _settledNotifier.value = !_controller.isAnimating;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.slideDuration,
    )..addStatusListener(_onSlideStatusChanged);
    _settledNotifier = ValueNotifier<bool>(!_controller.isAnimating);
    _curved = CurvedAnimation(parent: _controller, curve: widget.slideCurve);
    _toOffset = _targetOffset(widget);
    _fromOffset = _toOffset;
  }

  @override
  void didUpdateWidget(covariant SlidingPaneStrip oldWidget) {
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
      _settledNotifier.value = !_controller.isAnimating;
      return;
    }
    if (next == _toOffset) return;
    final current = _fromOffset + (_toOffset - _fromOffset) * _curved.value;
    _fromOffset = current;
    _toOffset = next;
    _controller
      ..stop()
      ..forward(from: 0);
    _settledNotifier.value = !_controller.isAnimating;
  }

  double _targetOffset(SlidingPaneStrip w) {
    final start = math.max(0, w.panes.length - w.visibleCount);
    return start * w.leftPaneWidth;
  }

  double _paneWidth(SlidingPaneStrip w, int index) {
    if (w.visibleCount < 2) return w.leftPaneWidth;
    final start = math.max(0, w.panes.length - w.visibleCount);
    if (index == start + 1) return w.rightPaneWidth;
    return w.leftPaneWidth;
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onSlideStatusChanged);
    _settledNotifier.dispose();
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
                SlidingPaneFrame(
                  pane: panes[i],
                  index: i,
                  depth: panes.length,
                  width: _paneWidth(widget, i),
                  height: widget.viewportHeight,
                  ticking: i >= start,
                  settledListenable: _settledNotifier,
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
                      ? PaneCardShell(child: widget.placeholder)
                      : widget.placeholder,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
