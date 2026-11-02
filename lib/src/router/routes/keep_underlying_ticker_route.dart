import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/offstage_host.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/pages/adaptive_page.dart';

/// 保持 `ModalRoute.opaqueOf(context)` 与 `AdaptiveRoute.opaque` 一致（确保 Android
/// `FadeForwardsPageTransitionsBuilder` 在压入三级路由时为下层页面包裹不透明的
/// `ColoredBox(color: ColorScheme.of(context).surface)` 底衬，避免露出黑色底幕闪烁），
/// 同时始终将自身 [OverlayEntry.opaque] 保持为 `false`，避免 [OverlayState] 关闭下层路由的
/// [TickerMode] 导致下层页面触发 `didChangeDependencies` 重解析图标闪白；
/// 并通过 [OffstagePageHost] 在上层不透明路由入场完成后将下层被遮挡页面标记为
/// `DiagnosticsTreeStyle.offstage`，使 Flutter DevTools `WidgetInspector` 点击选择时
/// 直接跳过被遮挡的根页面与中间页。
mixin KeepUnderlyingTickerRoute<T> on PageRoute<T> {
  static final Expando<List<KeepUnderlyingTickerRoute<dynamic>>>
  _routesByNavigator = Expando<List<KeepUnderlyingTickerRoute<dynamic>>>();

  final ValueNotifier<bool> _offstageNotifier = ValueNotifier<bool>(false);

  NavigatorState? _registeredNavigator;

  AdaptivePage<T>? _lastBuiltPage;

  Widget wrapOffstageContent(Widget child) {
    return OffstagePageHost(
      offstageListenable: _offstageNotifier,
      child: child,
    );
  }

  void _onRouteStatusChanged(AnimationStatus status) {
    _keepOverlayNonOpaque(status);
    _syncNavigatorOffstage();
  }

  void _keepOverlayNonOpaque([AnimationStatus? _]) {
    if (overlayEntries.isEmpty) return;
    overlayEntries.first.opaque = false;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    if (nextRoute is MaterialRouteTransitionMixin) {
      return true;
    }
    return super.canTransitionTo(nextRoute);
  }

  static int _pageIndexOf(
    KeepUnderlyingTickerRoute<dynamic> route,
    List<Page<dynamic>> pages,
  ) {
    final s = route.settings;
    if (s is! Page<dynamic>) return -1;
    for (var i = 0; i < pages.length; i++) {
      if (identical(pages[i], s) ||
          (pages[i].key != null && pages[i].key == s.key)) {
        return i;
      }
    }
    return -1;
  }

  void _syncNavigatorOffstage([NavigatorState? targetNavigator]) {
    final nav = targetNavigator ?? _registeredNavigator ?? navigator;
    if (nav == null || !nav.mounted) return;
    final list = _routesByNavigator[nav];
    if (list == null || list.isEmpty) return;
    final pages = nav.widget.pages;
    var highestCompletedOpaqueIndex = -1;
    for (final route in list) {
      if (!route.isActive || !route.opaque) continue;
      if (route.animation?.status != AnimationStatus.completed) continue;
      final idx = _pageIndexOf(route, pages);
      if (idx > highestCompletedOpaqueIndex) {
        highestCompletedOpaqueIndex = idx;
      }
    }
    for (final route in list) {
      final idx = _pageIndexOf(route, pages);
      final shouldOffstage =
          idx >= 0 && route.isActive && idx < highestCompletedOpaqueIndex;
      route._offstageNotifier.value = shouldOffstage;
    }
  }

  @override
  void install() {
    final current = settings;
    if (current is AdaptivePage<T>) {
      _lastBuiltPage = current;
    }
    super.install();
    final nav = navigator;
    if (nav != null) {
      _registeredNavigator = nav;
      final list = _routesByNavigator[nav] ??=
          <KeepUnderlyingTickerRoute<dynamic>>[];
      if (!list.contains(this)) {
        list.add(this);
      }
    }
    animation?.addStatusListener(_onRouteStatusChanged);
    _keepOverlayNonOpaque();
    _syncNavigatorOffstage(nav);
  }

  @override
  void didAdd() {
    super.didAdd();
    _keepOverlayNonOpaque();
    _syncNavigatorOffstage();
  }

  @override
  TickerFuture didPush() {
    final future = super.didPush();
    _keepOverlayNonOpaque();
    _syncNavigatorOffstage();
    return future;
  }

  @override
  bool didPop(T? result) {
    final popped = super.didPop(result);
    _keepOverlayNonOpaque();
    _syncNavigatorOffstage();
    return popped;
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    super.didPopNext(nextRoute);
    _syncNavigatorOffstage();
  }

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    super.didChangeNext(nextRoute);
    _syncNavigatorOffstage();
  }

  @override
  void changedExternalState() {
    _syncNavigatorOffstage();
    final current = settings;
    if (current is AdaptivePage<T>) {
      final previous = _lastBuiltPage;
      _lastBuiltPage = current;
      if (previous != null && !current.shouldRebuild(previous)) {
        return;
      }
    }
    super.changedExternalState();
  }

  @override
  void dispose() {
    animation?.removeStatusListener(_onRouteStatusChanged);
    final nav = _registeredNavigator ?? navigator;
    if (nav != null) {
      _routesByNavigator[nav]?.remove(this);
      _syncNavigatorOffstage(nav);
    }
    _registeredNavigator = null;
    _offstageNotifier.dispose();
    super.dispose();
  }
}
