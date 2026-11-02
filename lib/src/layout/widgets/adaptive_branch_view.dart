import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/breadcrumbs.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/pane_scope.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/sliding_pane_viewport.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/widgets/adaptive_branch_navigator.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_router.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_shell_route.dart';

/// 单个分支：1 栏用声明式 Navigator，2 栏用滑动视口。
class AdaptiveBranchView extends StatelessWidget {
  const AdaptiveBranchView({
    super.key,
    required this.navigatorKey,
    this.chromeNavigatorKey,
    required this.router,
    required this.shell,
    required this.branchIndex,
    required this.matches,
    required this.visibleCount,
    required this.keepState,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<NavigatorState>? chromeNavigatorKey;
  final AdaptiveRouter router;
  final AdaptiveShellRoute shell;
  final int branchIndex;
  final List<AdaptiveRouteMatch> matches;
  final int visibleCount;

  /// 非 compact：页面子树带 GlobalKey，跨 840 断点搬家时保留 State。
  final bool keepState;

  List<SlidingPane> _panes(BuildContext context) {
    return [
      for (final match in matches)
        SlidingPane(
          key: match.pageKey,
          title: match.title,
          child: keepState
              ? router.keepAlive(match, router.buildMatch(context, match))
              : router.buildMatch(context, match),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();
    if (visibleCount < 2) {
      return AdaptiveBranchNavigator(
        key: navigatorKey,
        chromeNavigatorKey: chromeNavigatorKey,
        pages: [
          for (final match in matches)
            router.pageFor(context, match, keepState: true),
        ],
        onDidRemovePage: router.handleRemovedPage,
        transitionDelegate: router.relocationDelegate,
      );
    }
    final panes = _panes(context);
    final branch = shell.branches[branchIndex];
    void onSelect(SlidingPane pane) {
      router.popUntil((match) => match.pageKey == pane.key);
    }

    return Column(
      children: [
        if (shell.showBreadcrumbs)
          shell.breadcrumbsBuilder?.call(context, panes, onSelect) ??
              AdaptiveBreadcrumbs(panes: panes, onSelect: onSelect),
        Expanded(
          child: SignalBuilder(
            builder: (context) {
              return SlidingPaneViewport(
                panes: panes,
                visibleCount: visibleCount,
                onPop: router.maybePop,
                placeholder:
                    branch.placeholder?.call(context) ??
                    shell.placeholder?.call(context),
                leftPaneFraction: router.leftPaneFraction.value,
                minLeftPaneFraction: shell.minLeftPaneFraction,
                minRightPaneFraction: shell.minRightPaneFraction,
                onLeftPaneFractionChanged: (value) {
                  router.leftPaneFraction.value = value;
                  shell.onLeftPaneFractionChanged?.call(value);
                },
                resizeLeftPane: shell.resizable,
                slideDuration: shell.slideDuration,
                slideCurve: shell.slideCurve,
                paneBuilder: shell.paneBuilder,
                resizeHandleWidth: shell.resizeHandleWidth,
                resizeHandleMargin: shell.resizeHandleMargin,
                resizeHandleBuilder: shell.resizeHandleBuilder,
              );
            },
          ),
        ),
      ],
    );
  }
}
