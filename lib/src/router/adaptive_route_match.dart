import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_core.dart';

import 'adaptive_route.dart';
import 'adaptive_route_state.dart';

/// [AdaptiveRouter.popUntil] / [pushNamedAndRemoveUntil] 的谓词。
typedef AdaptiveRoutePredicate = bool Function(AdaptiveRouteMatch match);

/// 一次路由匹配：对应页面栈中的一页 / 一栏。
class AdaptiveRouteMatch {
  /// [route] 为命中的表项；[matchedLocation] 为本层实际 path。
  AdaptiveRouteMatch({
    required this.route,
    required this.matchedLocation,
    required this.fullPath,
    required this.pathParameters,
    required this.queryParameters,
    required this.pageKey,
    required this.title,
    this.arguments,
    this.completer,
    this.isImperative = false,
    this.branchIndex,
  });

  /// 命中的 [AdaptiveRoute]。
  final AdaptiveRoute route;

  /// 本层实际 path，例如 `/mail/inbox/42`。
  final String matchedLocation;

  /// 模式，例如 `/mail/:folder/:threadId`。
  final String fullPath;

  /// 从根到本层累积的路径参数。
  final Map<String, String> pathParameters;

  /// 本次导航 URI 的 query。
  final Map<String, String> queryParameters;

  /// `pushNamed(..., arguments:)`。
  final Object? arguments;

  /// Navigator / 栏位保活 key。URL 推导为 `ValueKey(matchedLocation)`。
  final LocalKey pageKey;

  /// 面包屑标题，页面可通过 [AdaptivePaneScope.title] 改写。
  final Signal<String> title;

  /// 命令式 push 时的结果 Completer；URL 推导的 match 为 null。
  final Completer<Object?>? completer;

  /// 是否由 pushNamed 压到栈顶（而非 URL 栈前缀补齐）。
  final bool isImperative;

  /// 所属 [AdaptiveBranch] 下标；壳外路由为 null。
  final int? branchIndex;

  /// 路由表里的 [AdaptiveRoute.name]，未命名则为 null。
  String? get name => route.name;

  bool _disposed = false;

  /// 是否叠在根 Navigator 上。
  bool get isOverlay => route.onRootNavigator || branchIndex == null;

  /// 把本匹配转成 builder 用的 [AdaptiveRouteState]。
  ///
  /// [uri] 为当前路由器 location（可能是覆盖层的 URI）。
  /// [error] 透传 MatchList 级错误。
  AdaptiveRouteState toState(Uri uri, {Exception? error}) {
    return AdaptiveRouteState(
      uri: uri,
      matchedLocation: matchedLocation,
      fullPath: fullPath,
      name: route.name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      arguments: arguments,
      error: error,
      pageKey: pageKey,
    );
  }

  /// 本匹配对应的 location（path + 本层 query）。
  Uri get uri {
    return Uri(
      path: matchedLocation,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  /// 复制并覆盖命令式字段。不 dispose 原 title。
  AdaptiveRouteMatch copyWith({
    LocalKey? pageKey,
    Completer<Object?>? completer,
    bool? isImperative,
    Object? arguments,
    Map<String, String>? queryParameters,
    Signal<String>? title,
  }) {
    return AdaptiveRouteMatch(
      route: route,
      matchedLocation: matchedLocation,
      fullPath: fullPath,
      pathParameters: pathParameters,
      queryParameters: queryParameters ?? this.queryParameters,
      arguments: arguments ?? this.arguments,
      pageKey: pageKey ?? this.pageKey,
      title: title ?? this.title,
      completer: completer ?? this.completer,
      isImperative: isImperative ?? this.isImperative,
      branchIndex: branchIndex,
    );
  }

  /// 完成 [completer] 并销毁 [title]。已 dispose 则忽略。
  void dispose([Object? result]) {
    if (completer != null && !completer!.isCompleted) {
      completer!.complete(result);
    }
    if (_disposed) return;
    _disposed = true;
    title.dispose();
  }
}
