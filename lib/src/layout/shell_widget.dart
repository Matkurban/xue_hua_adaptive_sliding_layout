import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/breadcrumbs.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/pane_scope.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/sliding_pane_viewport.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_router.dart';

import '../router/adaptive_route_match.dart';
import '../router/adaptive_shell_route.dart';
import '../router/adaptive_shell_scope.dart';
import '../router/adaptive_shell_state.dart';

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
      (index) =>
          GlobalKey<NavigatorState>(debugLabel: 'adaptive-branch-$index'),
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

  /// compact 下分支栈从哪个下标起盖住宿主 chrome；没有则 [matches.length]。
  ///
  /// 第一个 [AdaptiveRoute.hidesBottomBarWhenPushed] 为 true 的非根页及其上
  /// 所有页都进 cover Navigator：更深的页在栈上本来就在它之上。
  static int _coverStart(List<AdaptiveRouteMatch> matches) {
    for (var i = 1; i < matches.length; i++) {
      if (matches[i].route.hidesBottomBarWhenPushed) return i;
    }
    return matches.length;
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
            final compact = _shell.breakpoints.isCompact(width);
            final shellState = AdaptiveShellState(
              currentIndex: _router.currentBranch.value,
              branchCount: _shell.branches.length,
              width: width,
              breakpoints: _shell.breakpoints,
              leftPaneFraction: _router.leftPaneFraction,
              goBranch: _router.goBranch,
            );
            final stacks = [
              for (var i = 0; i < _shell.branches.length; i++)
                _router.stackForBranch(i),
            ];
            final child = IndexedStack(
              index: shellState.currentIndex,
              sizing: StackFit.expand,
              children: [
                for (var i = 0; i < stacks.length; i++)
                  _BranchView(
                    navigatorKey: _navKeys[i],
                    router: _router,
                    shell: _shell,
                    branchIndex: i,
                    matches: compact
                        ? stacks[i].take(_coverStart(stacks[i])).toList()
                        : stacks[i],
                    visibleCount: columns,
                  ),
              ],
            );
            // cover Navigator 常驻包住 chrome：非 compact 时只有 chrome 一页，
            // 推页或跨断点缩放都不会重建壳。
            // ponytail: 只挂当前分支的 cover 页，其他分支的深层页在 compact 下
            // 不保活（底栏被盖住时切不了 Tab）；升级路径是每分支一个透明底页的
            // Navigator。
            final current = stacks[shellState.currentIndex];
            final chrome = Navigator(
              pages: [
                MaterialPage<void>(
                  key: const ValueKey<String>('adaptive-chrome'),
                  child: _shell.builder(context, shellState, child),
                ),
                if (compact)
                  for (final match in current.skip(_coverStart(current)))
                    _router.pageFor(context, match),
              ],
              onDidRemovePage: _router.handleRemovedPage,
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
                  // 壳页带上 PopEntry，根 Navigator 换上壳时不会发出
                  // canHandlePop: false 盖掉壳内 PopScope。onPop 不设，返回仍走 popRoute。
                  child: NavigatorPopHandler(child: chrome),
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
        pages: [for (final match in matches) router.pageFor(context, match)],
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
                resizeHandleBuilder: shell.resizeHandleBuilder,
              );
            },
          ),
        ),
      ],
    );
  }
}
