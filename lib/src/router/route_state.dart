import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/layout_breakpoints.dart';

/// 当前匹配到的路由快照，作为 [AdaptiveRoute.builder] 的第二参数。
///
/// 字段与 Navigator 的 [RouteSettings] 对齐：[arguments] 即
/// `pushNamed(..., arguments:)` 传入的对象；[name] 是路由表里的可选名字，
/// 不是 location。子树通过 [of] / [maybeOf] 读取。
class AdaptiveRouteState {
  /// [uri] 为当前 location；[matchedLocation] 为本层已匹配的 path（不含 query）。
  const AdaptiveRouteState({
    required this.uri,
    required this.matchedLocation,
    required this.fullPath,
    required this.pageKey,
    this.name,
    this.pathParameters = const <String, String>{},
    this.queryParameters = const <String, String>{},
    this.arguments,
    this.error,
  });

  /// 当前浏览器 / 路由器 location，含 query。
  final Uri uri;

  /// 本层匹配到的 path，例如 `/mail/inbox/42`。
  final String matchedLocation;

  /// 路由表中的完整模式，例如 `/mail/:folder/:threadId`。
  final String fullPath;

  /// [AdaptiveRoute.name]，未命名则为 null。
  final String? name;

  /// 路径参数，例如 `{'threadId': '42'}`。
  final Map<String, String> pathParameters;

  /// URI query，值已是字符串。
  final Map<String, String> queryParameters;

  /// `pushNamed(..., arguments:)` 带来的不透明对象，对应 [RouteSettings.arguments]。
  final Object? arguments;

  /// 无匹配或 redirect 循环时的错误；正常导航为 null。
  final Exception? error;

  /// 本页在 Navigator / 栏位中的 key，保活用。
  final LocalKey pageKey;

  /// 位于 [AdaptiveRouteScope] 内时返回当前状态；否则 assert。
  static AdaptiveRouteState of(BuildContext context) {
    final scope = AdaptiveRouteScope.maybeOf(context);
    assert(scope != null, 'AdaptiveRouteState not found in context');
    return scope!;
  }

  /// 位于路由页内时返回，否则 null（壳层、对话框外）。
  static AdaptiveRouteState? maybeOf(BuildContext context) {
    return AdaptiveRouteScope.maybeOf(context);
  }
}

/// 向子树暴露 [AdaptiveRouteState]。
class AdaptiveRouteScope extends InheritedWidget {
  /// [state] 为本页匹配快照。
  const AdaptiveRouteScope({
    super.key,
    required this.state,
    required super.child,
  });

  /// 当前页的路由快照。
  final AdaptiveRouteState state;

  /// 子树内返回 [state]，否则 null。
  static AdaptiveRouteState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdaptiveRouteScope>()
        ?.state;
  }

  /// [state] 的 uri / 参数变化时通知。
  @override
  bool updateShouldNotify(AdaptiveRouteScope oldWidget) =>
      state.uri != oldWidget.state.uri ||
      state.matchedLocation != oldWidget.state.matchedLocation ||
      state.arguments != oldWidget.state.arguments ||
      state.error != oldWidget.state.error;
}

/// [AdaptiveShellRoute.builder] 收到的壳层状态：当前分支、宽度、断点、分割比例。
class AdaptiveShellState {
  /// [goBranch] 切换 Tab；[leftPaneFraction] 为各 Tab 共用的左栏比例 signal。
  AdaptiveShellState({
    required this.currentIndex,
    required this.branchCount,
    required this.width,
    required this.breakpoints,
    required this.leftPaneFraction,
    required this.goBranch,
  });

  /// 当前选中的 [AdaptiveBranch] 下标。
  final int currentIndex;

  /// 分支总数。
  final int branchCount;

  /// [LayoutBuilder] 测到的壳层宽度。
  final double width;

  /// 本壳使用的断点。
  final LayoutBreakpoints breakpoints;

  /// 双栏左栏比例。松手后写回，拖拽中由视口本地更新。
  final Signal<double> leftPaneFraction;

  /// 切到 [index] 对应分支。
  ///
  /// [initialLocation] 为 true 时忽略该分支上次位置，回到
  /// [AdaptiveBranch.initialLocation]。
  final void Function(int index, {bool initialLocation}) goBranch;

  /// 当前宽度是否低于 compact。
  bool get isCompact => breakpoints.isCompact(width);

  /// 当前宽度是否为 medium。
  bool get isMedium => breakpoints.isMedium(width);

  /// 当前宽度是否达到 expanded。
  bool get isExpanded => breakpoints.isExpanded(width);

  /// 视口应显示的栏数（1 或 2）。
  int get visibleColumnCount => breakpoints.visibleColumnCount(width);
}

/// 向子树暴露 [AdaptiveShellState]。
class AdaptiveShellScope extends InheritedWidget {
  /// [state] 由内部壳层在每次 layout 时重建。
  const AdaptiveShellScope({
    super.key,
    required this.state,
    required super.child,
  });

  /// 当前壳层快照。
  final AdaptiveShellState state;

  /// 位于壳内时返回，否则 null。
  static AdaptiveShellState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdaptiveShellScope>()
        ?.state;
  }

  /// 读取壳层状态；不在壳内时 assert。
  static AdaptiveShellState of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'AdaptiveShellState not found in context');
    return scope!;
  }

  /// 下标、宽度或断点变化时通知（rail / 栏数）。
  @override
  bool updateShouldNotify(AdaptiveShellScope oldWidget) {
    return state.currentIndex != oldWidget.state.currentIndex ||
        state.width != oldWidget.state.width ||
        state.breakpoints != oldWidget.state.breakpoints;
  }
}
