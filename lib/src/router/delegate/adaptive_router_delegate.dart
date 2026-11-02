import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/shell_widget.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match_list.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_scope.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_router.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_router_scope.dart';

/// 路由器代理：驱动根 [Navigator] 并协调系统返回。
class AdaptiveRouterDelegate extends RouterDelegate<AdaptiveRouteMatchList>
    with ChangeNotifier {
  AdaptiveRouterDelegate(this.router);

  final AdaptiveRouter router;

  /// 供 [AdaptiveRouter] 在栈变化后通知 [Router]。
  void notify() => notifyListeners();

  @override
  AdaptiveRouteMatchList? get currentConfiguration =>
      router.isReady ? router.currentConfigurationMatchList : null;

  @override
  Future<void> setNewRoutePath(AdaptiveRouteMatchList configuration) {
    return router.applyParsed(configuration);
  }

  @override
  Future<void> setInitialRoutePath(AdaptiveRouteMatchList configuration) {
    return router.applyParsed(configuration);
  }

  @override
  Future<bool> popRoute() async {
    final navs = _currentNavigators();
    if (navs.isNotEmpty && await navs.first.maybePop()) {
      // 2 栏栏内 Navigator 只有一页：maybePop 只消化 LocalHistoryEntry，
      // 其 onRemove 已经调用 router.maybePop()（含 onExit）。这里不再补弹，
      // 否则 onExit 刚弹出的确认框会被立刻关掉。
      return true;
    }
    if (router.canPop()) {
      await router.maybePop();
      return true;
    }
    for (final nav in navs.skip(1)) {
      if (await nav.maybePop()) return true;
    }
    final top = router.currentConfigurationMatchList.last;
    return top?.route.onExit != null && !await router.allowExit(top!);
  }

  /// 栈顶页所在 Navigator → … → 根 Navigator；被上层 pageless 路由压住的内层不问。
  ///
  /// 不能用 [Navigator.maybeOf]：3.47 起它在 Navigator 自己的 context 上返回自身。
  List<NavigatorState> _currentNavigators() {
    final root = router.navigatorKey.currentState;
    if (root == null) return const <NavigatorState>[];
    final top = router.currentConfigurationMatchList.last;
    final chain = <NavigatorState>[];
    NavigatorState? nav =
        (top == null ? null : router.hostRouteFor(top.pageKey)?.navigator) ??
        root;
    final seen = <NavigatorState>{};
    while (nav != null && seen.add(nav)) {
      chain.add(nav);
      if (nav == root) break;
      nav = nav.context.findAncestorStateOfType<NavigatorState>();
    }
    if (chain.isEmpty || chain.last != root) {
      chain.add(root);
    }
    var start = 0;
    for (var i = 0; i < chain.length - 1; i++) {
      if (ModalRoute.of(chain[i].context)?.isCurrent == false) {
        start = i + 1;
      }
    }
    return chain.sublist(start);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveRouterScope(
      router: router,
      child: Navigator(
        key: router.navigatorKey,
        observers: router.observers,
        pages: _pages(context),
        onDidRemovePage: router.handleRemovedPage,
      ),
    );
  }

  List<Page<dynamic>> _pages(BuildContext context) {
    final current = router.currentConfigurationMatchList;
    final pages = <Page<dynamic>>[];
    if (current.error != null &&
        current.matches.isEmpty &&
        router.errorBuilder != null) {
      pages.add(_errorPage(context, current));
      return pages;
    }
    if (current.shell != null && current.branchIndex != null) {
      pages.add(
        const AdaptiveContainerPage<void>(
          key: ValueKey<String>('adaptive-shell'),
          child: AdaptiveShellPage(),
        ),
      );
    } else if (router.shell != null &&
        current.overlayMatches.isNotEmpty &&
        router.hasSavedBranches) {
      pages.add(
        const AdaptiveContainerPage<void>(
          key: ValueKey<String>('adaptive-shell'),
          child: AdaptiveShellPage(),
        ),
      );
    }
    for (final overlay in current.overlayMatches) {
      pages.add(router.pageFor(context, overlay));
    }
    if (pages.isEmpty && router.errorBuilder != null) {
      pages.add(_errorPage(context, current));
    }
    if (pages.isEmpty) {
      pages.add(
        const AdaptiveContainerPage<void>(
          key: ValueKey<String>('adaptive-empty'),
          child: SizedBox.shrink(),
        ),
      );
    }
    return pages;
  }

  Page<dynamic> _errorPage(
    BuildContext context,
    AdaptiveRouteMatchList current,
  ) {
    final state = router.stateFor(current, current.uri);
    return AdaptiveContainerPage<void>(
      key: const ValueKey<String>('adaptive-error'),
      child: AdaptiveRouteScope(
        state: state,
        child: router.errorBuilder!(context, state),
      ),
    );
  }
}

/// 从 scope 取 router 再画壳，避免 MaterialPage.child 在构造时抓不到 InheritedWidget。
class AdaptiveShellPage extends StatelessWidget {
  const AdaptiveShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveShellHost(router: AdaptiveRouter.of(context));
  }
}
