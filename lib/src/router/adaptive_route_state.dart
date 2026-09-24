import 'package:flutter/widgets.dart';

import 'adaptive_route_scope.dart';

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
