import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/shell_widget.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/match.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/navigation.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/route.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/route_state.dart';

/// 自适应多栏路由器：路由表借鉴 go_router，调用 API 与 [NavigatorState] 同名。
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
  }) : registry = RouteRegistry(routes),
       navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>() {
    WidgetsFlutterBinding.ensureInitialized();
    _engine = NavigationEngine(registry);
    final effective = _effectiveInitial(initialLocation);
    _current = AdaptiveRouteMatchList(
      matches: const <AdaptiveRouteMatch>[],
      uri: Uri.parse(effective),
    );
    location = signal(effective);
    matches = signal(_current);
    currentBranch = signal(0);
    leftPaneFraction = signal(shell?.initialLeftPaneFraction ?? 0.5);
    routeInformationProvider = PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(uri: Uri.parse(effective)),
    );
    routeInformationParser = _AdaptiveRouteInformationParser(this);
    _delegate = _AdaptiveRouterDelegate(this);
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

  /// 编译后的路由表。
  final RouteRegistry registry;

  late NavigationEngine _engine;
  late final _AdaptiveRouterDelegate _delegate;

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
  final Map<int, List<AdaptiveRouteMatch>> _branchStacks =
      <int, List<AdaptiveRouteMatch>>{};
  final Map<int, String> _branchLocations = <int, String>{};

  /// 每页当前所在的 [ModalRoute]，供 [maybePop] / [popRoute] 问 PopScope。
  final Map<LocalKey, ModalRoute<dynamic>> _hostRoutes =
      <LocalKey, ModalRoute<dynamic>>{};

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
    final popup = _popupNavigator();
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
    final popup = _popupNavigator();
    if (popup != null) return popup.maybePop<T>(result);
    return _maybePopPage(result);
  }

  /// 与 [pop] 一样不问 [PopScope] / [AdaptiveRoute.onExit]，但只动 [context] 所在的那一层。
  ///
  /// - context 在 dialog / sheet / menu 里：关掉它所在 Navigator 的栈顶（通常就是它自己）。
  /// - context 在某页里且该页被弹层盖住：关掉盖住它的弹层（栏内 → 壳层 → 根，外层优先）。
  /// - context 在栈顶页里且没被盖住：弹出该页。
  /// - context 在非栈顶页里且没被盖住：不动。
  /// - context 不在任何页面 / 弹层里（壳层 chrome、壳外）：等同 [pop]。
  ///
  /// 双栏时左右两栏各开了一个 sheet，传哪个 context 就关哪个。
  void popFrom<T extends Object?>(BuildContext context, [T? result]) {
    switch (_layerOf(context)) {
      case _PopupLayer(:final navigator):
        navigator.pop<T>(result);
      case _TopPageLayer():
        _popPage(result);
      case _GlobalLayer():
        pop<T>(result);
      case _IdleLayer():
        break;
    }
  }

  /// [popFrom] 的询问版：弹层走它自己的 [PopScope]；页面走 [PopScope] → [AdaptiveRoute.onExit]。
  /// 返回是否真的弹了。
  Future<bool> maybePopFrom<T extends Object?>(
    BuildContext context, [
    T? result,
  ]) {
    return switch (_layerOf(context)) {
      _PopupLayer(:final navigator) => navigator.maybePop<T>(result),
      _TopPageLayer() => _maybePopPage(result),
      _GlobalLayer() => maybePop<T>(result),
      _IdleLayer() => Future<bool>.value(false),
    };
  }

  /// 直接弹出栈顶页，不问 [PopScope] / onExit；栈底时不动。
  void _popPage(Object? result) {
    if (!_current.canPop) return;
    _setCurrent(_engine.pop(_current, result));
  }

  /// 栈顶页的询问路径：栈底 → false；页内 [PopScope] 否决 → false；再问 onExit，通过则出栈。
  ///
  /// 不问 [ModalRoute.isCurrent]：2 栏栏内 [LocalHistoryEntry] 的 onRemove 调用
  /// [maybePop] 时，该 pageless 路由可能已经不是 current，但页面还在自适应栈顶。
  Future<bool> _maybePopPage(Object? result) async {
    if (!_current.canPop) return false;
    final top = _current.last!;
    final route = _hostRoutes[top.pageKey];
    if (route != null) {
      final disposition = route is _ExitGuard
          ? route.scopeDisposition
          : route.popDisposition;
      if (disposition == RoutePopDisposition.doNotPop) {
        route.onPopInvokedWithResult(false, result);
        return false;
      }
    }
    return _exitThenPop(top, result);
  }

  /// [context] 落在哪一层，供 [popFrom] / [maybePopFrom] 决定动什么。
  _Layer _layerOf(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null) return const _GlobalLayer();
    if (!_hostRoutes.containsValue(route)) {
      // 托管页面之外：pageless 的是 dialog / sheet / menu，带 Page 的是壳层容器页。
      final nav = route.navigator;
      if (route.settings is Page || nav == null) return const _GlobalLayer();
      return _PopupLayer(nav);
    }
    final popup = _popupOver(route);
    if (popup != null) return _PopupLayer(popup);
    final top = _current.last;
    if (top != null && identical(_hostRoutes[top.pageKey], route)) {
      return const _TopPageLayer();
    }
    return const _IdleLayer();
  }

  /// PopScope 已放行后：询问 onExit，通过且栈顶未变则出栈。
  Future<bool> _exitThenPop(AdaptiveRouteMatch top, Object? result) async {
    if (!await _allowExit(top)) return false;
    if (_current.last != top) return false;
    _setCurrent(_engine.pop(_current, result));
    return true;
  }

  /// 与 [Navigator.popUntil] 同名：弹到 [predicate] 为 true 或不能再弹。
  ///
  /// 先关掉盖住栈顶页的 dialog、sheet、menu，再按 [predicate] 弹页面。
  void popUntil(AdaptiveRoutePredicate predicate) {
    _dismissPopups();
    _setCurrent(_engine.popUntil(_current, predicate));
  }

  /// 盖住栈顶页的 pageless 路由（dialog、sheet、menu）所在的 [NavigatorState]；没有则 null。
  ///
  /// 只看栈顶页那一栏及其祖先（壳层、根）；双栏时另一栏的栏内弹层由 [popFrom] /
  /// [maybePopFrom] 处理。
  NavigatorState? _popupNavigator() {
    final top = _current.last;
    final host = top == null ? null : _hostRoutes[top.pageKey];
    return host == null ? null : _popupOver(host);
  }

  /// 盖住 [page] 的弹层所在 Navigator：先祖先链（根、壳层，外层优先，因为外层弹层
  /// 盖住一切），再 [page] 自己的 Navigator。栏内 local history 不算弹层，因为它不会
  /// 让页面路由失去 [ModalRoute.isCurrent]。
  NavigatorState? _popupOver(ModalRoute<dynamic> page) {
    NavigatorState? found;
    var nav = page.navigator;
    final seen = <NavigatorState>{};
    while (nav != null && seen.add(nav)) {
      final parent = ModalRoute.of(nav.context);
      if (parent == null) break;
      if (_coveredByPopup(parent)) found = parent.navigator;
      nav = parent.navigator;
    }
    return found ?? (_coveredByPopup(page) ? page.navigator : null);
  }

  /// [route] 本该在其 Navigator 顶上却被压住，且压住它的不是本路由器托管的页面。
  bool _coveredByPopup(ModalRoute<dynamic> route) {
    final nav = route.navigator;
    if (nav == null || route.isCurrent || !nav.canPop()) return false;
    return !_hostRoutes.values.any(
      (page) => identical(page.navigator, nav) && page.isCurrent,
    );
  }

  /// 逐个关掉盖住页面的弹层，页面栈不动。
  ///
  /// ponytail: 最多 32 层。再多说明 [Navigator.pop] 没拆掉路由，停下来避免空转。
  void _dismissPopups() {
    for (var i = 0; i < 32; i++) {
      final popup = _popupNavigator();
      if (popup == null) return;
      popup.pop<Object?>();
    }
  }

  /// 与 [Navigator.canPop] 同名。
  bool canPop() => _current.canPop;

  /// 重新对当前 URI 跑 redirect（登录态变化后调用）。
  void refresh() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    resolve(context, _current.uri, arguments: _current.arguments).then((next) {
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
      final stored = _branchStacks[index];
      if (stored != null && stored.isNotEmpty) {
        _setCurrent(
          _engine.goBranch(
            _current,
            location: _branchLocations[index] ?? branch.initialLocation,
            restored: stored,
          ),
        );
        return;
      }
    }
    final loc = initialLocation
        ? branch.initialLocation
        : (_branchLocations[index] ?? branch.initialLocation);
    _setCurrent(_engine.goBranch(_current, location: loc));
  }

  /// 解析 URI 并跑顶层 / 路由级 redirect，供 Parser 与 [refresh] 使用。
  Future<AdaptiveRouteMatchList> resolve(
    BuildContext context,
    Uri uri, {
    Object? arguments,
  }) async {
    var current = uri;
    for (var hop = 0; hop < redirectLimit; hop++) {
      if (!context.mounted) {
        return registry.match(current, arguments: arguments);
      }
      final matched = registry.match(current, arguments: arguments);
      final state = _stateFor(matched, current);
      final top = await redirect?.call(context, state);
      if (top != null && !_sameLocation(current, top)) {
        current = _parse(top);
        continue;
      }
      if (!context.mounted) {
        return matched;
      }
      var redirected = false;
      for (final match in matched.matches) {
        if (!context.mounted) return matched;
        final next = await match.route.redirect?.call(
          context,
          match.toState(current, error: matched.error),
        );
        if (next != null && !_sameLocation(current, next)) {
          current = _parse(next);
          redirected = true;
          break;
        }
      }
      if (redirected) continue;
      return matched;
    }
    return AdaptiveRouteMatchList(
      matches: const <AdaptiveRouteMatch>[],
      uri: current,
      error: Exception('Redirect loop after $redirectLimit hops'),
    );
  }

  /// 当前分支应展示的栈；非当前分支用上次快照或 initialLocation。
  List<AdaptiveRouteMatch> stackForBranch(int index) {
    if (_current.branchIndex == index) return _current.branchMatches;
    final stored = _branchStacks[index];
    if (stored != null && stored.isNotEmpty) return stored;
    final shellRoute = shell;
    if (shellRoute == null || index >= shellRoute.branches.length) {
      return const <AdaptiveRouteMatch>[];
    }
    return registry
        .match(Uri.parse(shellRoute.branches[index].initialLocation))
        .branchMatches;
  }

  /// 把 match 建成带 [AdaptiveRouteScope] 的页面子树。
  Widget buildMatch(BuildContext context, AdaptiveRouteMatch match) {
    final state = match.toState(_current.uri, error: _current.error);
    final built =
        match.route.builder?.call(context, state) ?? const SizedBox.shrink();
    return AdaptiveRouteScope(
      state: state,
      child: _PageHost(router: this, pageKey: match.pageKey, child: built),
    );
  }

  /// 根 Navigator / 1 栏 Navigator 使用的 [Page]。
  Page<dynamic> pageFor(BuildContext context, AdaptiveRouteMatch match) {
    return _AdaptivePage<Object?>(
      key: match.pageKey,
      name: match.matchedLocation,
      arguments: match.arguments,
      router: this,
      match: match,
      child: buildMatch(context, match),
    );
  }

  /// 根 / 栏内 Navigator 在系统 pop 掉一页后同步栈。
  void handleRemovedPage(Page<dynamic> page) {
    handleRemovedPageKey(page.key, null);
  }

  /// 若 [key] 仍在当前栈顶则 pop，避免与 [pop] 双重出栈。
  void handleRemovedPageKey(LocalKey? key, Object? result) {
    if (key == null) return;
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
      _parse(routeName),
      arguments: arguments,
    );
    if (resolved.error != null && resolved.matches.isEmpty) {
      return routeName;
    }
    return _loc(resolved.uri);
  }

  Future<bool> _allowExit(AdaptiveRouteMatch match) async {
    final onExit = match.route.onExit;
    if (onExit == null) return true;
    final context = navigatorKey.currentContext;
    if (context == null) return true;
    return onExit(context, match.toState(_current.uri, error: _current.error));
  }

  Future<bool> _allowExitAll(Iterable<AdaptiveRouteMatch> removing) async {
    for (final match in removing) {
      if (!await _allowExit(match)) return false;
    }
    return true;
  }

  Future<void> applyParsed(AdaptiveRouteMatchList configuration) async {
    if (_ready && _sameUri(_current.uri, configuration.uri)) {
      return;
    }
    if (_ready) {
      final removing = [
        for (final match in _current.matches.reversed)
          if (!_containsKey(configuration, match.pageKey)) match,
      ];
      if (!await _allowExitAll(removing)) {
        _delegate.notify();
        return;
      }
    }
    _setCurrent(configuration);
  }

  void _setCurrent(AdaptiveRouteMatchList next) {
    final old = _current;
    if (old.branchIndex != null &&
        old.branchIndex != next.branchIndex &&
        old.branchMatches.isNotEmpty) {
      _branchStacks[old.branchIndex!] = old.branchMatches;
      _branchLocations[old.branchIndex!] = _branchLoc(old);
    }
    if (next.branchIndex != null) {
      _branchStacks[next.branchIndex!] = next.branchMatches;
      _branchLocations[next.branchIndex!] = _branchLoc(next);
    }
    final kept = <Key>{
      for (final match in next.matches) match.pageKey,
      for (final stack in _branchStacks.values)
        for (final match in stack) match.pageKey,
    };
    for (final match in old.matches) {
      if (!kept.contains(match.pageKey)) {
        match.dispose();
      }
    }
    _current = next;
    _ready = true;
    location.value = _loc(next.uri);
    matches.value = next;
    if (next.branchIndex != null) {
      currentBranch.value = next.branchIndex!;
    }
    _delegate.notify();
  }

  AdaptiveRouteState _stateFor(AdaptiveRouteMatchList list, Uri uri) {
    final last = list.last;
    if (last != null) return last.toState(uri, error: list.error);
    return AdaptiveRouteState(
      uri: uri,
      matchedLocation: uri.path.isEmpty ? '/' : uri.path,
      fullPath: uri.path,
      pageKey: const ValueKey<String>('adaptive-empty'),
      queryParameters: uri.queryParameters,
      arguments: list.arguments,
      error: list.error,
    );
  }

  Future<T?> _wait<T>(AdaptiveRouteMatchList next) {
    final completer = next.last?.completer;
    if (completer == null) return Future<T?>.value(null);
    return completer.future.then((value) => value as T?);
  }

  static bool _containsKey(AdaptiveRouteMatchList list, LocalKey key) {
    return list.matches.any((match) => match.pageKey == key);
  }

  static String _branchLoc(AdaptiveRouteMatchList list) {
    final branch = list.branchMatches;
    if (branch.isEmpty) return _loc(list.uri);
    return _loc(branch.last.uri);
  }

  static String _loc(Uri uri) {
    if (uri.hasQuery) return '${uri.path}?${uri.query}';
    return uri.path.isEmpty ? '/' : uri.path;
  }

  static Uri _parse(String routeName) {
    if (!routeName.startsWith('/')) return Uri.parse('/$routeName');
    return Uri.parse(routeName);
  }

  static bool _sameLocation(Uri uri, String other) {
    final parsed = _parse(other);
    return uri.path == parsed.path && uri.query == parsed.query;
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

/// 向子树暴露 [AdaptiveRouter]。
class AdaptiveRouterScope extends InheritedWidget {
  /// [router] 为本应用唯一的路由器实例。
  const AdaptiveRouterScope({
    super.key,
    required this.router,
    required super.child,
  });

  /// 当前路由器。
  final AdaptiveRouter router;

  @override
  bool updateShouldNotify(AdaptiveRouterScope oldWidget) =>
      router != oldWidget.router;
}

class _AdaptiveRouteInformationParser
    extends RouteInformationParser<AdaptiveRouteMatchList> {
  _AdaptiveRouteInformationParser(this.router);

  final AdaptiveRouter router;

  @override
  Future<AdaptiveRouteMatchList> parseRouteInformationWithDependencies(
    RouteInformation routeInformation,
    BuildContext context,
  ) {
    return router.resolve(context, routeInformation.uri);
  }

  @override
  RouteInformation? restoreRouteInformation(
    AdaptiveRouteMatchList configuration,
  ) {
    return RouteInformation(uri: configuration.uri);
  }
}

class _AdaptiveRouterDelegate extends RouterDelegate<AdaptiveRouteMatchList>
    with ChangeNotifier {
  _AdaptiveRouterDelegate(this.router);

  final AdaptiveRouter router;

  /// 供 [AdaptiveRouter] 在栈变化后通知 [Router]。
  void notify() => notifyListeners();

  @override
  AdaptiveRouteMatchList? get currentConfiguration =>
      router._ready ? router._current : null;

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
    final top = router._current.last;
    return top?.route.onExit != null && !await router._allowExit(top!);
  }

  /// 栈顶页所在 Navigator → … → 根 Navigator；被上层 pageless 路由压住的内层不问。
  ///
  /// 不能用 [Navigator.maybeOf]：3.47 起它在 Navigator 自己的 context 上返回自身。
  List<NavigatorState> _currentNavigators() {
    final root = router.navigatorKey.currentState;
    if (root == null) return const <NavigatorState>[];
    final top = router._current.last;
    final chain = <NavigatorState>[];
    NavigatorState? nav =
        (top == null ? null : router._hostRoutes[top.pageKey]?.navigator) ??
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
    final current = router._current;
    final pages = <Page<dynamic>>[];
    if (current.error != null &&
        current.matches.isEmpty &&
        router.errorBuilder != null) {
      pages.add(_errorPage(context, current));
      return pages;
    }
    if (current.shell != null && current.branchIndex != null) {
      pages.add(
        const MaterialPage<void>(
          key: ValueKey<String>('adaptive-shell'),
          child: _ShellPage(),
        ),
      );
    } else if (router.shell != null &&
        current.overlayMatches.isNotEmpty &&
        router._branchStacks.isNotEmpty) {
      pages.add(
        const MaterialPage<void>(
          key: ValueKey<String>('adaptive-shell'),
          child: _ShellPage(),
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
        const MaterialPage<void>(
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
    final state = router._stateFor(current, current.uri);
    return MaterialPage<void>(
      key: const ValueKey<String>('adaptive-error'),
      child: AdaptiveRouteScope(
        state: state,
        child: router.errorBuilder!(context, state),
      ),
    );
  }
}

/// 从 scope 取 router 再画壳，避免 MaterialPage.child 在构造时抓不到 InheritedWidget。
class _ShellPage extends StatelessWidget {
  const _ShellPage();

  @override
  Widget build(BuildContext context) {
    return AdaptiveShellHost(router: AdaptiveRouter.of(context));
  }
}

/// 声明式页：Material 过场或自定义 [AdaptiveRoute.transitionsBuilder]。
class _AdaptivePage<T> extends Page<T> {
  const _AdaptivePage({
    required this.router,
    required this.match,
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  final AdaptiveRouter router;
  final AdaptiveRouteMatch match;
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    if (match.route.transitionsBuilder != null) {
      return _AdaptiveTransitionRoute<T>(page: this);
    }
    return _AdaptiveMaterialRoute<T>(page: this);
  }
}

/// [AdaptiveRouter.popFrom] / [AdaptiveRouter.maybePopFrom] 对 context 的落点。
sealed class _Layer {
  const _Layer();
}

/// 要关的弹层所在 Navigator。
final class _PopupLayer extends _Layer {
  const _PopupLayer(this.navigator);

  final NavigatorState navigator;
}

/// context 在栈顶页里且没被盖住：走页面路径。
final class _TopPageLayer extends _Layer {
  const _TopPageLayer();
}

/// context 在非栈顶页里且没被盖住：无事可做。
final class _IdleLayer extends _Layer {
  const _IdleLayer();
}

/// context 不在托管页面 / 弹层里（壳层 chrome、壳外）：回落到全局动词。
final class _GlobalLayer extends _Layer {
  const _GlobalLayer();
}

/// 页面路由的 onExit 守卫：先让页内 PopScope 表态，再由 onExit 否决，二者互不覆盖。
mixin _ExitGuard<T> on ModalRoute<T> {
  AdaptiveRouter get router;
  AdaptiveRouteMatch get match;

  /// 不含 onExit 否决的 disposition；doNotPop 即页内 PopScope 否决。
  RoutePopDisposition get scopeDisposition => super.popDisposition;

  @override
  RoutePopDisposition get popDisposition {
    final inner = super.popDisposition;
    return match.route.onExit != null && inner == RoutePopDisposition.pop
        ? RoutePopDisposition.doNotPop
        : inner;
  }

  @override
  void onPopInvokedWithResult(bool didPop, T? result) {
    super.onPopInvokedWithResult(didPop, result);
    if (didPop) {
      router.handleRemovedPageKey(match.pageKey, result);
    } else if (match.route.onExit != null &&
        scopeDisposition != RoutePopDisposition.doNotPop) {
      unawaited(router._exitThenPop(match, result));
    }
  }
}

/// 与 Flutter 私有 `_PageBasedMaterialPageRoute` 对齐的 Material 页路由。
class _AdaptiveMaterialRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T>, _ExitGuard<T> {
  _AdaptiveMaterialRoute({required _AdaptivePage<T> page})
    : super(
        settings: page,
        fullscreenDialog: page.match.route.fullscreenDialog,
      );

  _AdaptivePage<T> get _page => settings as _AdaptivePage<T>;

  @override
  AdaptiveRouter get router => _page.router;

  @override
  AdaptiveRouteMatch get match => _page.match;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  bool get maintainState => true;
}

/// 自定义过场的页路由。
class _AdaptiveTransitionRoute<T> extends PageRouteBuilder<T>
    with _ExitGuard<T> {
  _AdaptiveTransitionRoute({required _AdaptivePage<T> page})
    : super(
        settings: page,
        fullscreenDialog: page.match.route.fullscreenDialog,
        opaque: page.match.route.opaque,
        barrierColor: page.match.route.barrierColor,
        barrierDismissible: page.match.route.barrierDismissible,
        transitionDuration:
            page.match.route.transitionDuration ??
            const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => page.child,
        transitionsBuilder: page.match.route.transitionsBuilder!,
      );

  _AdaptivePage<T> get _page => settings as _AdaptivePage<T>;

  @override
  AdaptiveRouter get router => _page.router;

  @override
  AdaptiveRouteMatch get match => _page.match;
}

/// 记下本页所在 [ModalRoute]，供路由器询问 PopScope / 走 Navigator 链。
class _PageHost extends StatefulWidget {
  const _PageHost({
    required this.router,
    required this.pageKey,
    required this.child,
  });

  final AdaptiveRouter router;
  final LocalKey pageKey;
  final Widget child;

  @override
  State<_PageHost> createState() => _PageHostState();
}

class _PageHostState extends State<_PageHost> {
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route == route) return;
    _unbind();
    _route = route;
    if (route != null) {
      widget.router._hostRoutes[widget.pageKey] = route;
    }
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  void _unbind() {
    if (_route == null) return;
    if (widget.router._hostRoutes[widget.pageKey] == _route) {
      widget.router._hostRoutes.remove(widget.pageKey);
    }
    _route = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
