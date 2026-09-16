import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/breadcrumbs.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/pane_scope.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/sliding_pane_viewport.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_router.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/match.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/route.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/route_state.dart';

/// 内部壳：按宽度在 1 栏 [Navigator] 与 2 栏 [SlidingPaneViewport] 之间切换。
///
/// 由 [AdaptiveRouter] 的根 Navigator 挂载。宿主 UI 走 [AdaptiveShellRoute.builder]。
class AdaptiveShellHost extends StatefulWidget {
  /// [router] 必须已经匹配到一个 [AdaptiveShellRoute]。
  const AdaptiveShellHost({super.key, required this.router});

  /// 当前路由器。
  final AdaptiveRouter router;

  @override
  State<AdaptiveShellHost> createState() => _AdaptiveShellHostState();
}

class _AdaptiveShellHostState extends State<AdaptiveShellHost> {
  late List<GlobalKey<NavigatorState>> _navKeys;

  AdaptiveRouter get _router => widget.router;

  AdaptiveShellRoute get _shell => _router.shell!;

  @override
  void initState() {
    super.initState();
    _navKeys = List<GlobalKey<NavigatorState>>.generate(
      _shell.branches.length,
      (index) => GlobalKey<NavigatorState>(debugLabel: 'adaptive-branch-$index'),
    );
  }

  @override
  void didUpdateWidget(covariant AdaptiveShellHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shell.branches.length != _navKeys.length) {
      _navKeys = List<GlobalKey<NavigatorState>>.generate(
        _shell.branches.length,
        (index) =>
            GlobalKey<NavigatorState>(debugLabel: 'adaptive-branch-$index'),
      );
    }
  }

  void _onEscape() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus is EditableTextState) return;
    _router.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        _router.matches.value;
        _router.currentBranch.value;
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final columns = _shell.breakpoints.visibleColumnCount(width);
            final shellState = AdaptiveShellState(
              currentIndex: _router.currentBranch.value,
              branchCount: _shell.branches.length,
              width: width,
              breakpoints: _shell.breakpoints,
              leftPaneFraction: _router.leftPaneFraction,
              goBranch: _router.goBranch,
            );
            final child = IndexedStack(
              index: shellState.currentIndex,
              sizing: StackFit.expand,
              children: [
                for (var i = 0; i < _shell.branches.length; i++)
                  _BranchView(
                    navigatorKey: _navKeys[i],
                    router: _router,
                    shell: _shell,
                    branchIndex: i,
                    matches: _router.stackForBranch(i),
                    visibleCount: columns,
                  ),
              ],
            );
            return AdaptiveShellScope(
              state: shellState,
              child: CallbackShortcuts(
                bindings: {
                  if (_shell.escapePops)
                    const SingleActivator(LogicalKeyboardKey.escape): _onEscape,
                },
                child: Focus(
                  autofocus: true,
                  child: _shell.builder(context, shellState, child),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 单个分支：1 栏用声明式 Navigator，2 栏用滑动视口。
class _BranchView extends StatelessWidget {
  const _BranchView({
    required this.navigatorKey,
    required this.router,
    required this.shell,
    required this.branchIndex,
    required this.matches,
    required this.visibleCount,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final AdaptiveRouter router;
  final AdaptiveShellRoute shell;
  final int branchIndex;
  final List<AdaptiveRouteMatch> matches;
  final int visibleCount;

  List<SlidingPane> _panes(BuildContext context) {
    return [
      for (final match in matches)
        SlidingPane(
          key: match.pageKey,
          title: match.title,
          child: router.buildMatch(context, match),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();
    if (visibleCount < 2) {
      return Navigator(
        key: navigatorKey,
        pages: [
          for (final match in matches) router.pageFor(context, match),
        ],
        onDidRemovePage: router.handleRemovedPage,
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
                onPop: () {
                  router.maybePop();
                },
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
                resizeHandleBuilder: shell.resizeHandleBuilder,
              );
            },
          ),
        ),
      ],
    );
  }
}
