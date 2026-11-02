import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/offstage_host.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/pane_scope.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/widgets/pane_card_shell.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/widgets/pane_navigator.dart';

/// 单栏：屏外屏蔽语义、焦点与指针命中（保留 TickerMode 避免图片重解析闪白）；
/// 可见栏包 [AdaptivePaneScope] 与栏内 Navigator。
class SlidingPaneFrame extends StatelessWidget {
  const SlidingPaneFrame({
    super.key,
    required this.pane,
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
    this.layoutKey,
    this.paneBuilder,
  });

  final SlidingPane pane;
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
  final Key? layoutKey;
  final SlidingPaneFrameBuilder? paneBuilder;

  @override
  Widget build(BuildContext context) {
    final inner = ExcludeSemantics(
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
    );
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
