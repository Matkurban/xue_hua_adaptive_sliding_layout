import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_base.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match_list.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_scope.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_state.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_router_scope.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_shell_route.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/delegate/adaptive_route_information_parser.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/delegate/adaptive_router_delegate.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/delegate/relocation_transition_delegate.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/internal/branch_stack_store.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/internal/navigation_layer.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/internal/popup_layer_resolver.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/internal/route_redirect_resolver.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/navigation.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/pages/adaptive_page.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/pages/adaptive_page_host.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/route_registry.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/routes/exit_guard_route_mixin.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/transitions/adaptive_page_transition_type.dart';

export 'pages/adaptive_container_page.dart';

/// 自适应多栏路由器。调用 API 与 [NavigatorState] 同名。
///
/// 交给 [MaterialApp.router] 的 `routerConfig`。页面内用 [of] / [maybeOf]
/// 取实例再 `pushNamed` / `pop`；也可以直接持有本对象，无需依赖注入。
class AdaptiveRouter implements RouterConfig<AdaptiveRouteMatchList> {
  /// [routes] 为顶层路由表；[initialLocation] 在平台未给出 URL 时使用。
  AdaptiveRouter({
    required List<AdaptiveRouteBase> routes,
    String initialLocation = '/',
    this.redirect,
    this.errorBuilder,
    GlobalKey<NavigatorState>? navigatorKey,
    this.observers = const <NavigatorObserver>[],
    this.redirectLimit = 5,
    this.defaultTransitionType,
    this.defaultTransitionsBuilder,
    this.defaultTransitionDuration,
    this.defaultReverseTransitionDuration,
    this.defaultTransitionCurve,
    this.defaultReverseTransitionCurve,
  }) : registry = RouteRegistry(routes),
       navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>() {
    WidgetsFlutterBinding.ensureInitialized();
    _engine = NavigationEngine(registry);
    _branchStore = BranchStackStore(registry);
    _popupResolver = PopupLayerResolver(_hostRoutes);
    _redirectResolver = RouteRedirectResolver(
      registry: registry,
      redirect: redirect,
      redirectLimit: redirectLimit,
    );
    final effective = _effectiveInitial(initialLocation);
    _current = AdaptiveRouteMatchList(
      matches: const <AdaptiveRouteMatch>[],
      uri: Uri.parse(effective),
    );
    location = signal(effective);
    matches = signal(_current);
    currentBranch = signal(0);
    leftPaneFraction = signal(shell?.initialLeftPaneFraction ?? 0.4);
    routeInformationProvider = PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(uri: Uri.parse(effective)),
    );
    routeInformationParser = AdaptiveRouteInformationParser(this);
    _delegate = AdaptiveRouterDelegate(this);
    routerDelegate = _delegate;
    backButtonDispatcher = RootBackButtonDispatcher();
  }

  /// 顶层 redirect。返回非 null location 则改去那里。
  final AdaptiveRedirect? redirect;

  /// 无匹配或 redirect 循环时的页面。
  final AdaptiveRouteBuilder? errorBuilder;

  /// 根 Navigator 的 key，供无 context 的调用和 Overlay 查找。
  final GlobalKey<NavigatorState> navigatorKey;

  /// 根 Navigator 观察者。
  final List<NavigatorObserver> observers;

  /// redirect 最大跳数，超出视为循环。
  final int redirectLimit;

  /// 全局默认页面过渡动画类型（低于单页 [AdaptiveRoute.transitionType] 与壳级 [AdaptiveShellRoute.transitionType]）。
  final AdaptivePageTransitionType? defaultTransitionType;

  /// 全局默认页面过渡构建器（低于单页 [AdaptiveRoute.transitionsBuilder] 与壳级 [AdaptiveShellRoute.transitionsBuilder]）。
  final AdaptiveTransitionsBuilder? defaultTransitionsBuilder;

  /// 全局默认页面入场过渡时长。
  final Duration? defaultTransitionDuration;

  /// 全局默认页面退场过渡时长。
  final Duration? defaultReverseTransitionDuration;

  /// 全局默认页面正向过渡曲线。
  final Curve? defaultTransitionCurve;

  /// 全局默认页面反向过渡曲线。
  final Curve? defaultReverseTransitionCurve;

  /// 编译后的路由表。
  final RouteRegistry registry;

  late final NavigationEngine _engine;
  late final BranchStackStore _branchStore;
  late final PopupLayerResolver _popupResolver;
  late final RouteRedirectResolver _redirectResolver;
  late final AdaptiveRouterDelegate _delegate;

  @override
  late final RouteInformationProvider routeInformationProvider;

  @override
  late final RouteInformationParser<AdaptiveRouteMatchList>
  routeInformationParser;

  @override
  late final RouterDelegate<AdaptiveRouteMatchList> routerDelegate;

  @override
  late final BackButtonDispatcher backButtonDispatcher;

  /// 当前 location（path + query），页面可用 [SignalBuilder] 订阅。
  late final Signal<String> location;

  /// 当前完整匹配栈。
  late final Signal<AdaptiveRouteMatchList> matches;

  /// 当前分支下标。
  late final Signal<int> currentBranch;

  /// 双栏左栏比例，各 Tab 共用。
  late final Signal<double> leftPaneFraction;

  /// 顶层壳；没有 [AdaptiveShellRoute] 则为 null。
  AdaptiveShellRoute? get shell => registry.shell;

  late AdaptiveRouteMatchList _current;

  bool _ready = false;

  /// 是否已完成首次路由应用（供内部 [AdaptiveRouterDelegate] 读取）。
  bool get isReady => _ready;

  /// 当前完整匹配结果（供内部 [AdaptiveRouterDelegate] 读取）。
  AdaptiveRouteMatchList get currentConfigurationMatchList => _current;

  /// 是否已有保存过的分支栈快照（供内部 [AdaptiveRouterDelegate] 判断壳层保留）。
  bool get hasSavedBranches => _branchStore.hasSavedBranches;

  /// 每页当前所在的 [ModalRoute]，供 [maybePop] / `popRoute` 问 PopScope。
  final Map<LocalKey, ModalRoute<dynamic>> _hostRoutes =
      <LocalKey, ModalRoute<dynamic>>{};

  /// 查询指定 [pageKey] 当前挂载的 [ModalRoute]。
  ModalRoute<dynamic>? hostRouteFor(LocalKey pageKey) => _hostRoutes[pageKey];

  /// 登记页面 [pageKey] 所在的 [ModalRoute]（由 [AdaptivePageHost] 调用）。
  void registerHostRoute(LocalKey pageKey, ModalRoute<dynamic> route) {
    _hostRoutes[pageKey] = route;
  }

  /// 解绑页面 [pageKey] 所在的 [ModalRoute]（由 [AdaptivePageHost] 调用）。
  void unregisterHostRoute(LocalKey pageKey, ModalRoute<dynamic> route) {
    if (_hostRoutes[pageKey] == route) {
      _hostRoutes.remove(pageKey);
    }
  }

  /// 位于 [AdaptiveRouterScope] 内时返回路由器；否则 assert。
  static AdaptiveRouter of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'AdaptiveRouter not found in context');
    return scope!;
  }

  /// 位于路由器子树内时返回，否则 null。
  static AdaptiveRouter? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdaptiveRouterScope>()
        ?.router;
  }

  /// 把命名路由展开成 location，再交给 `*Named` 动词。
  String namedLocation(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  }) {
    return registry.namedLocation(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
    );
  }

  /// 与 [Navigator.pushNamed] 同名。见方案三条规则。
  Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) async {
    final next = await _navigatePush(routeName, arguments: arguments);
    return _wait<T>(next);
  }

  /// 与 [Navigator.pushReplacementNamed] 同名：只换栈顶。
  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) async {
    final location = await _redirected(routeName, arguments);
    final next = _engine.pushReplacementNamed(
      _current,
      location,
      result: result,
      arguments: arguments,
    );
    _setCurrent(next);
    return _wait<T>(next);
  }

  /// 与 [Navigator.pushNamedAndRemoveUntil] 同名。
  ///
  /// [predicate] 恒为 `(_) => false` 时按 URL 重建整栈（深链、登录回跳、Tab 回根）。
  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String routeName,
    AdaptiveRoutePredicate predicate, {
    Object? arguments,
  }) async {
    final location = await _redirected(routeName, arguments);
    final next = _engine.pushNamedAndRemoveUntil(
      _current,
      location,
      predicate,
      arguments: arguments,
    );
    _setCurrent(next);
    return _wait<T>(next);
  }

  /// 与 [Navigator.popAndPushNamed] 同名。
  Future<T?> popAndPushNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) async {
    final location = await _redirected(routeName, arguments);
    final next = _engine.popAndPushNamed(
      _current,
      location,
      result: result,
      arguments: arguments,
    );
    _setCurrent(next);
    return _wait<T>(next);
  }

  /// 与 [Navigator.pop] 同名：不询问 [AdaptiveRoute.onExit]。
  ///
  /// 栈顶页上若有 dialog、sheet 或 menu（栏内、壳层或根），只关掉那一层，页面栈不动。
  /// 只看栈顶那一栏：双栏时另一栏的栏内弹层用 [popFrom] 关。
  void pop<T extends Object?>([T? result]) {
    final popup = _popupResolver.popupNavigator(_current);
    if (popup != null) {
      popup.pop<T>(result);
      return;
    }
    _popPage(result);
  }

  /// 与 [Navigator.maybePop] 同名：先问栈顶页内 [PopScope]，再问 [AdaptiveRoute.onExit]。
  ///
  /// 栈顶页上若有 dialog、sheet 或 menu，改为询问那一层（含其 [PopScope]），
  /// 不再问页面的 [AdaptiveRoute.onExit]。只看栈顶那一栏：双栏时另一栏的栏内弹层
  /// 用 [maybePopFrom] 关。
  /// AppBar 返回、系统返回、浏览器后退、Escape 都走这里。
  /// 栈底（[canPop] 为 false）时返回 false，不弹退出确认——那是系统返回 / popRoute 的事。
  Future<bool> maybePop<T extends Object?>([T? result]) {
    final popup = _popupResolver.popupNavigator(_current);
    if (popup != null) return popup.maybePop<T>(result);
    return _maybePopPage(result);
  }

  /// 与 [pop] 一样不问 [PopScope] / [AdaptiveRoute.onExit]，但只动 [context] 所在的那一层。
  void popFrom<T extends Object?>(BuildContext context, [T? result]) {
    switch (_popupResolver.layerOf(context, _current)) {
      case PopupNavigationLayer(:final navigator):
        navigator.pop<T>(result);
      case TopPageNavigationLayer():
        _popPage(result);
      case GlobalNavigationLayer():
        pop<T>(result);
      case IdleNavigationLayer():
        break;
    }
  }

  /// [popFrom] 的询问版：弹层走它自己的 [PopScope]；页面走 [PopScope] → [AdaptiveRoute.onExit]。
  /// 返回是否真的弹了。
  Future<bool> maybePopFrom<T extends Object?>(
    BuildContext context, [
    T? result,
  ]) {
    return switch (_popupResolver.layerOf(context, _current)) {
      PopupNavigationLayer(:final navigator) => navigator.maybePop<T>(result),
      TopPageNavigationLayer() => _maybePopPage(result),
      GlobalNavigationLayer() => maybePop<T>(result),
      IdleNavigationLayer() => Future<bool>.value(false),
    };
  }

  /// 直接弹出栈顶页，不问 [PopScope] / onExit；栈底时不动。
  void _popPage(Object? result) {
    if (!_current.canPop) return;
    _setCurrent(_engine.pop(_current, result));
  }

  /// 栈顶页的询问路径：栈底 → false；页内 [PopScope] 否决 → false；再问 onExit，通过则出栈。
  Future<bool> _maybePopPage(Object? result) async {
    if (!_current.canPop) return false;
    final top = _current.last!;
    final route = _hostRoutes[top.pageKey];
    if (route != null) {
      final disposition = route is ExitGuardRouteMixin
          ? route.scopeDisposition
          : route.popDisposition;
      if (disposition == RoutePopDisposition.doNotPop) {
        route.onPopInvokedWithResult(false, result);
        return false;
      }
    }
    return exitThenPop(top, result);
  }

  /// PopScope 已放行后：询问 onExit，通过且栈顶未变则出栈。
  Future<bool> exitThenPop(AdaptiveRouteMatch top, Object? result) async {
    if (!await allowExit(top)) return false;
    if (_current.last != top) return false;
    _setCurrent(_engine.pop(_current, result));
    return true;
  }

  /// 与 [Navigator.popUntil] 同名：弹到 [predicate] 为 true 或不能再弹。
  ///
  /// 先关掉盖住栈顶页的 dialog、sheet、menu，再按 [predicate] 弹页面。
  void popUntil(AdaptiveRoutePredicate predicate) {
    _popupResolver.dismissPopups(_current);
    _setCurrent(_engine.popUntil(_current, predicate));
  }

  /// 与 [Navigator.canPop] 同名。
  bool canPop() => _current.canPop;

  /// 重新对当前 URI 跑 redirect（登录态变化后调用）。
  void refresh() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final before = _current;
    resolve(context, before.uri, arguments: before.arguments).then((next) {
      final unchanged = next.error == null && _sameUri(next.uri, before.uri);
      if (unchanged || !identical(_current, before)) {
        RouteRedirectResolver.disposeMatches(next.matches);
        return;
      }
      _setCurrent(next);
    });
  }

  /// 切到 [index] 对应分支。已访问过的分支恢复上次栈，否则按 initialLocation 匹配。
  void goBranch(int index, {bool initialLocation = false}) {
    final shellRoute = shell;
    if (shellRoute == null) return;
    if (index < 0 || index >= shellRoute.branches.length) return;
    final branch = shellRoute.branches[index];
    if (!initialLocation) {
      final stored = _branchStore.branchStacks[index];
      if (stored != null && stored.isNotEmpty) {
        _setCurrent(
          _engine.goBranch(
            _current,
            location:
                _branchStore.branchLocations[index] ?? branch.initialLocation,
            restored: stored,
          ),
        );
        return;
      }
    }
    final loc = initialLocation
        ? branch.initialLocation
        : (_branchStore.branchLocations[index] ?? branch.initialLocation);
    _setCurrent(_engine.goBranch(_current, location: loc));
  }

  /// 解析 URI 并跑顶层 / 路由级 redirect，供 Parser 与 [refresh] 使用。
  Future<AdaptiveRouteMatchList> resolve(
    BuildContext context,
    Uri uri, {
    Object? arguments,
  }) {
    return _redirectResolver.resolve(context, uri, arguments: arguments);
  }

  /// [index] 分支是否打开过（当前分支，或离开时存过栈）。没打开过的分支不建页面。
  bool hasVisitedBranch(int index) {
    return _branchStore.hasVisitedBranch(index, _current);
  }

  /// 当前分支应展示的栈；非当前分支用上次快照或 initialLocation。
  List<AdaptiveRouteMatch> stackForBranch(int index) {
    return _branchStore.stackForBranch(index, _current);
  }

  /// 把 match 建成带 [AdaptiveRouteScope] 的页面子树。
  Widget buildMatch(BuildContext context, AdaptiveRouteMatch match) {
    final state = match.toState(match.uri, error: _current.error);
    final built =
        match.route.builder?.call(context, state) ?? const SizedBox.shrink();
    return AdaptiveRouteScope(
      state: state,
      child: AdaptivePageHost(
        router: this,
        pageKey: match.pageKey,
        child: built,
      ),
    );
  }

  final Map<LocalKey, GlobalKey> _contentKeys = <LocalKey, GlobalKey>{};

  /// 每个页面一个稳定的 [GlobalKey]：跨断点时页面子树在 Navigator 与
  /// `SlidingPaneViewport` 之间搬家，State 随 key 一起被接管而不是重建。
  Widget keepAlive(AdaptiveRouteMatch match, Widget child) {
    final key = _contentKeys.putIfAbsent(
      match.pageKey,
      () => GlobalKey(debugLabel: 'adaptive-page-${match.pageKey}'),
    );
    return KeyedSubtree(key: key, child: child);
  }

  /// 根 Navigator / 1 栏 Navigator 使用的 [Page]。
  Page<dynamic> pageFor(
    BuildContext context,
    AdaptiveRouteMatch match, {
    bool keepState = false,
  }) {
    final raw = buildMatch(context, match);
    final built = keepState ? keepAlive(match, raw) : raw;
    return AdaptivePage<Object?>(
      key: match.pageKey,
      name: match.matchedLocation,
      arguments: match.arguments,
      router: this,
      match: match,
      branchIndex: currentBranch.value,
      error: _current.error,
      child: built,
    );
  }

  /// 根 / 栏内 Navigator 在系统 pop 掉一页后同步栈。
  void handleRemovedPage(Page<dynamic> page) {
    handleRemovedPageKey(page.key, null);
  }

  bool _relocatingPages = false;

  /// 壳内 Navigator 的转场代理：跨断点搬家那一帧，旧页面立即移除（不播退出
  /// 动画）、新页面直接加入，这样同一个 GlobalKey 的子树在同一帧里从旧
  /// Navigator 交接给新 Navigator，不会两边同时挂载。
  late final TransitionDelegate<dynamic> relocationDelegate =
      RelocationTransitionDelegate(() => _relocatingPages);

  /// 壳在跨 compact 断点的这一帧里把页面从一个 Navigator 搬到另一个。
  void beginPageRelocation() {
    if (_relocatingPages) return;
    _relocatingPages = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _relocatingPages = false,
    );
  }

  /// 若 [key] 仍在当前栈顶则 pop，避免与 [pop] 双重出栈。
  void handleRemovedPageKey(LocalKey? key, Object? result) {
    if (key == null || _relocatingPages) return;
    final last = _current.last;
    if (last == null || last.pageKey != key) return;
    _setCurrent(_engine.pop(_current, result));
  }

  Future<AdaptiveRouteMatchList> _navigatePush(
    String routeName, {
    Object? arguments,
  }) async {
    final location = await _redirected(routeName, arguments);
    final next = _engine.pushNamed(_current, location, arguments: arguments);
    _setCurrent(next);
    return next;
  }

  Future<String> _redirected(String routeName, Object? arguments) async {
    final context = navigatorKey.currentContext;
    if (context == null) return routeName;
    final resolved = await resolve(
      context,
      RouteRedirectResolver.parseLocation(routeName),
      arguments: arguments,
    );
    RouteRedirectResolver.disposeMatches(resolved.matches);
    if (resolved.error != null && resolved.matches.isEmpty) {
      return routeName;
    }
    return RouteRedirectResolver.formatLocation(resolved.uri);
  }

  /// 询问 [match] 的 [AdaptiveRoute.onExit] 是否允许离开。
  Future<bool> allowExit(AdaptiveRouteMatch match) async {
    final onExit = match.route.onExit;
    if (onExit == null) return true;
    final context = navigatorKey.currentContext;
    if (context == null) return true;
    return onExit(context, match.toState(_current.uri, error: _current.error));
  }

  Future<bool> _allowExitAll(Iterable<AdaptiveRouteMatch> removing) async {
    for (final match in removing) {
      if (!await allowExit(match)) return false;
    }
    return true;
  }

  Future<void> applyParsed(AdaptiveRouteMatchList configuration) async {
    if (_ready && _sameUri(_current.uri, configuration.uri)) {
      _branchStore.disposeUnkeptMatches(configuration.matches, _current);
      return;
    }
    if (_ready) {
      final removing = [
        for (final match in _current.matches.reversed)
          if (!_containsKey(configuration, match.pageKey)) match,
      ];
      if (!await _allowExitAll(removing)) {
        _branchStore.disposeUnkeptMatches(configuration.matches, _current);
        _delegate.notify();
        return;
      }
    }
    _setCurrent(configuration);
  }

  /// 释放路由器持有的所有 [Signal]、分支栈匹配与代理监听器。
  void dispose() {
    _branchStore.disposeAll(_current);
    _hostRoutes.clear();
    _contentKeys.clear();
    location.dispose();
    matches.dispose();
    currentBranch.dispose();
    leftPaneFraction.dispose();
    _delegate.dispose();
    if (routeInformationProvider is ChangeNotifier) {
      (routeInformationProvider as ChangeNotifier).dispose();
    }
  }

  void _setCurrent(AdaptiveRouteMatchList next) {
    final restored = _branchStore.restoreArguments(next.matches, _current);
    if (!identical(restored, next.matches)) {
      next = next.copyWith(matches: restored);
    }
    final old = _current;
    final kept = _branchStore.syncStacksOnTransition(old, next);
    // 页面保活 key 只在栈变化时清理：当前栈和所有分支快照里的页面保留，
    // build 路径上不做任何清理，切 Tab 时目标分支的 key 不会丢。
    _contentKeys.removeWhere((key, _) => !kept.contains(key));
    _current = next;
    _branchStore.rememberArguments(_current);
    _ready = true;
    location.value = RouteRedirectResolver.formatLocation(next.uri);
    matches.value = next;
    if (next.branchIndex != null) {
      currentBranch.value = next.branchIndex!;
    }
    _delegate.notify();
  }

  /// 将匹配结果 [list] 转换为顶层 redirect 或错误页使用的 [AdaptiveRouteState]。
  AdaptiveRouteState stateFor(AdaptiveRouteMatchList list, Uri uri) {
    return RouteRedirectResolver.stateFor(list, uri);
  }

  Future<T?> _wait<T>(AdaptiveRouteMatchList next) {
    final completer = next.last?.completer;
    if (completer == null) return Future<T?>.value(null);
    return completer.future.then((value) => value as T?);
  }

  static bool _containsKey(AdaptiveRouteMatchList list, LocalKey key) {
    return list.matches.any((match) => match.pageKey == key);
  }

  static bool _sameUri(Uri a, Uri b) => a.path == b.path && a.query == b.query;

  static String _effectiveInitial(String initialLocation) {
    final fromPlatform =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (fromPlatform.isNotEmpty && fromPlatform != '/') {
      return fromPlatform;
    }
    return initialLocation;
  }
}
