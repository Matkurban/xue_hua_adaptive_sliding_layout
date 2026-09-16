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
  void pop<T extends Object?>([T? result]) {
    if (!_current.canPop) return;
    _setCurrent(_engine.pop(_current, result));
  }

  /// 与 [Navigator.maybePop] 同名：询问栈顶 [AdaptiveRoute.onExit]。
  ///
  /// AppBar 返回、系统返回、浏览器后退、Escape 都走这里。
  Future<bool> maybePop<T extends Object?>([T? result]) async {
    if (!_current.canPop) return false;
    final top = _current.last;
    if (top != null && !await _allowExit(top)) {
      return false;
    }
    pop<T>(result);
    return true;
  }

  /// 与 [Navigator.popUntil] 同名：弹到 [predicate] 为 true 或不能再弹。
  void popUntil(AdaptiveRoutePredicate predicate) {
    _setCurrent(_engine.popUntil(_current, predicate));
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

  /// 切到 [index] 对应分支。内部等价于按该分支上次 location 重建。
  void goBranch(int index, {bool initialLocation = false}) {
    final shellRoute = shell;
    if (shellRoute == null) return;
    if (index < 0 || index >= shellRoute.branches.length) return;
    final branch = shellRoute.branches[index];
    final loc = initialLocation
        ? branch.initialLocation
        : (_branchLocations[index] ?? branch.initialLocation);
    final next = _engine.goBranch(_current, location: loc);
    _setCurrent(next);
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
    return AdaptiveRouteScope(state: state, child: built);
  }

  /// 根 Navigator / 1 栏 Navigator 使用的 [Page]。
  Page<dynamic> pageFor(BuildContext context, AdaptiveRouteMatch match) {
    final child = buildMatch(context, match);
    final hasExit = match.route.onExit != null;
    void onPopInvoked(bool didPop, Object? result) {
      if (didPop) {
        handleRemovedPageKey(match.pageKey, result);
        return;
      }
      maybePop(result);
    }

    if (match.route.transitionsBuilder != null) {
      return _AdaptiveTransitionPage<Object?>(
        key: match.pageKey,
        name: match.matchedLocation,
        arguments: match.arguments,
        canPop: !hasExit,
        onPopInvoked: onPopInvoked,
        fullscreenDialog: match.route.fullscreenDialog,
        opaque: match.route.opaque,
        barrierColor: match.route.barrierColor,
        barrierDismissible: match.route.barrierDismissible,
        transitionsBuilder: match.route.transitionsBuilder!,
        transitionDuration:
            match.route.transitionDuration ?? const Duration(milliseconds: 300),
        child: child,
      );
    }
    return MaterialPage<Object?>(
      key: match.pageKey,
      name: match.matchedLocation,
      arguments: match.arguments,
      canPop: !hasExit,
      onPopInvoked: onPopInvoked,
      fullscreenDialog: match.route.fullscreenDialog,
      child: child,
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
    final next = _engine.pushNamed(
      _current,
      location,
      arguments: arguments,
    );
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

  static bool _sameUri(Uri a, Uri b) =>
      a.path == b.path && a.query == b.query;

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
    final navigator = router.navigatorKey.currentState;
    if (navigator != null && await navigator.maybePop()) {
      return true;
    }
    return router.maybePop();
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

class _AdaptiveTransitionPage<T> extends Page<T> {
  const _AdaptiveTransitionPage({
    required this.child,
    required this.transitionsBuilder,
    required this.transitionDuration,
    this.opaque = true,
    this.barrierColor,
    this.barrierDismissible = false,
    this.fullscreenDialog = false,
    super.key,
    super.name,
    super.arguments,
    super.canPop,
    super.onPopInvoked,
  });

  final Widget child;
  final AdaptiveTransitionsBuilder transitionsBuilder;
  final Duration transitionDuration;
  final bool opaque;
  final Color? barrierColor;
  final bool barrierDismissible;
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      fullscreenDialog: fullscreenDialog,
      opaque: opaque,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      transitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: transitionsBuilder,
    );
  }
}
