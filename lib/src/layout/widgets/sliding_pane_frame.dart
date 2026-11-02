import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/offstage_host.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/pane_scope.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/widgets/pane_card_shell.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/widgets/pane_navigator.dart';

/// 单栏：屏外屏蔽语义、焦点与指针命中（保留 TickerMode 避免图片重解析闪白）；
/// 可见栏包 [AdaptivePaneScope] 与栏内 Navigator，并在右栏页面进入时执行过渡动画。
class SlidingPaneFrame extends StatelessWidget {
  const SlidingPaneFrame({
    super.key,
    required this.pane,
    required this.innerKey,
    required this.index,
    required this.depth,
    required this.width,
    required this.height,
    required this.ticking,
    required this.settledListenable,
    required this.decorate,
    required this.showDivider,
    required this.dividerColor,
    required this.onPop,
    required this.defaultSlideCurve,
    this.entranceAnimation,
    this.layoutKey,
    this.paneBuilder,
  });

  final SlidingPane pane;
  final GlobalKey innerKey;
  final int index;
  final int depth;
  final double width;
  final double height;
  final bool ticking;
  final ValueListenable<bool> settledListenable;
  final bool decorate;
  final bool showDivider;
  final Color dividerColor;
  final VoidCallback? onPop;
  final Curve defaultSlideCurve;
  final Animation<double>? entranceAnimation;
  final Key? layoutKey;
  final SlidingPaneFrameBuilder? paneBuilder;

  static const Animation<double> _zeroSecondaryAnimation =
      AlwaysStoppedAnimation<double>(0.0);

  Widget _buildAnimatedInner(BuildContext context, Widget inner) {
    final animation = entranceAnimation;
    if (animation == null) return inner;
    final curve = pane.transitionCurve ?? defaultSlideCurve;
    final customBuilder = pane.transitionsBuilder;
    return ClipRect(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          if (animation.value >= 1.0) return child!;
          if (customBuilder != null) {
            return customBuilder(
              context,
              animation,
              _zeroSecondaryAnimation,
              child!,
            );
          }
          final curvedValue = curve.transform(animation.value.clamp(0.0, 1.0));
          return Opacity(
            opacity: curvedValue.clamp(0.0, 1.0),
            child: FractionalTranslation(
              translation: Offset(0.18 * (1.0 - curvedValue), 0.0),
              child: child,
            ),
          );
        },
        child: inner,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coreInner = KeyedSubtree(
      key: innerKey,
      child: ExcludeSemantics(
        excluding: !ticking,
        child: ExcludeFocus(
          excluding: !ticking,
          child: IgnorePointer(
            ignoring: !ticking,
            child: PageStorage(
              bucket: PageStorage.of(context),
              child: KeyedSubtree(
                key: PageStorageKey<LocalKey>(pane.key),
                child: PaneNavigator(pane: pane, onPop: onPop),
              ),
            ),
          ),
        ),
      ),
    );
    final inner = _buildAnimatedInner(context, coreInner);
    final decorated = paneBuilder != null
        ? paneBuilder!(context, index, inner)
        : decorate
        ? PaneCardShell(child: inner)
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
          child: OffstagePageHost(
            offstageListenable: ticking ? null : settledListenable,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (layoutKey != null)
                  IgnorePointer(child: SizedBox.expand(key: layoutKey)),
                decorated,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
