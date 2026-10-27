import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/breadcrumbs.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/pane_scope.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/shell_bar.dart';
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

  /// 上一次 build 时是否 compact；用来发现跨 compact 断点的那一帧。
  bool? _wasCompact;

  /// 上一次 build 时的当前分支；用来发现切 Tab 的那一帧。
  int? _lastBranch;

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
      if (_router.currentBranch.value >= _shell.branches.length) {
        _router.currentBranch.value = _shell.branches.length - 1;
      }
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
            if (_wasCompact != null && _wasCompact != compact) {
              // 跨 compact 断点：页面会在分支 Navigator 与 cover Navigator 之间
              // 搬家，旧 Navigator 会把它们当作“被移除”并回调出栈，这一帧要忽略。
              _router.beginPageRelocation();
            }
            _wasCompact = compact;
            final shellState = AdaptiveShellState(
              currentIndex: _router.currentBranch.value,
              branchCount: _shell.branches.length,
              width: width,
              breakpoints: _shell.breakpoints,
              leftPaneFraction: _router.leftPaneFraction,
              goBranch: _router.goBranch,
            );
            // 从没打开过的分支不建页面：它的根页等第一次切过去时才创建，只建一次。
            final stacks = [
              for (var i = 0; i < _shell.branches.length; i++)
                _router.hasVisitedBranch(i)
                    ? _router.stackForBranch(i)
                    : const <AdaptiveRouteMatch>[],
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
                    keepState: true,
                  ),
              ],
            );
            // chrome Navigator：壳页 + 当前分支盖住底栏的 cover 页（compact）。
            // 其他分支的 cover 页“停放”在各自常驻的离屏 Navigator 里，页面和
            // State 都留在树上；切 Tab 时页面在两个 Navigator 之间同一帧交接
            // （稳定 GlobalKey + 无动画的转场代理），不会销毁重建。
            final current = stacks[shellState.currentIndex];
            if (_lastBranch != null && _lastBranch != shellState.currentIndex) {
              _router.beginPageRelocation();
            }
            _lastBranch = shellState.currentIndex;
            final chrome = Stack(
              fit: StackFit.expand,
              children: [
                Navigator(
                  pages: [
                    MaterialPage<void>(
                      key: const ValueKey<String>('adaptive-chrome'),
                      child: _shell.builder(context, shellState, child),
                    ),
                    if (compact)
                      for (final match in current.skip(_coverStart(current)))
                        _router.pageFor(context, match, keepState: true),
                  ],
                  onDidRemovePage: _router.handleRemovedPage,
                  transitionDelegate: _router.relocationDelegate,
                ),
                for (var i = 0; i < stacks.length; i++)
                  _ParkedCovers(
                    key: ValueKey<int>(i),
                    router: _router,
                    pages: compact && i != shellState.currentIndex
                        ? stacks[i].skip(_coverStart(stacks[i])).toList()
                        : const <AdaptiveRouteMatch>[],
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
    required this.keepState,
  });

  final GlobalKey<NavigatorState> navigatorKey;
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
      final frame = adaptiveShellBarFrame(context);
      return Navigator(
        key: navigatorKey,
        pages: [
          for (final match in matches)
            router.pageFor(context, match, frame: frame, keepState: true),
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

/// cover Navigator 的透明底页：[Navigator.pages] 不能为空，所以每个分支的
/// cover Navigator 常驻这一页，页面清空时它什么也不画（外层 IgnorePointer）。
class _CoverBasePage extends Page<void> {
  const _CoverBasePage()
    : super(key: const ValueKey<String>('adaptive-cover-base'));

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      opaque: false,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

/// 非当前分支的 cover 页停放处：离屏、无焦点、无语义、不响应点击，也不向上
/// 发 NavigationNotification（返回键只看 chrome Navigator）。
class _ParkedCovers extends StatelessWidget {
  const _ParkedCovers({super.key, required this.router, required this.pages});

  final AdaptiveRouter router;
  final List<AdaptiveRouteMatch> pages;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      child: ExcludeFocus(
        child: ExcludeSemantics(
          child: IgnorePointer(
            child: NotificationListener<NavigationNotification>(
              onNotification: (_) => true,
              child: Navigator(
                pages: [
                  const _CoverBasePage(),
                  for (final match in pages)
                    router.pageFor(context, match, keepState: true),
                ],
                onDidRemovePage: router.handleRemovedPage,
                transitionDelegate: router.relocationDelegate,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
