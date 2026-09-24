import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_core.dart';

import '../utils/match_utils.dart';
import '../utils/path_utils.dart';
import 'adaptive_route.dart';
import 'adaptive_route_base.dart';
import 'adaptive_route_match.dart';
import 'adaptive_route_match_list.dart';
import 'adaptive_route_state.dart';
import 'adaptive_shell_route.dart';
import 'named_route_ref.dart';
import 'path_pattern.dart';

/// 编译路由树：匹配 URI、按名展开 location、找到唯一壳。
class RouteRegistry {
  /// [routes] 为 [AdaptiveRouter] 顶层表。壳最多一个，必须在顶层。
  RouteRegistry(this.routes) {
    _walk(routes, parentFullPath: '', branchIndex: null);
  }

  /// 顶层路由表。
  final List<AdaptiveRouteBase> routes;

  AdaptiveShellRoute? _shell;

  final Map<String, NamedRouteRef> _named = <String, NamedRouteRef>{};

  /// 顶层唯一壳；没有壳则为 null。
  AdaptiveShellRoute? get shell => _shell;

  /// 已登记的命名路由。
  Map<String, NamedRouteRef> get namedRoutes => Map.unmodifiable(_named);

  /// 深度优先登记命名路由，并断言只有一个顶层壳。
  void _walk(
    Iterable<AdaptiveRouteBase> nodes, {
    required String parentFullPath,
    required int? branchIndex,
  }) {
    for (final node in nodes) {
      switch (node) {
        case AdaptiveShellRoute():
          if (_shell != null) {
            throw StateError(
              'ponytail: only one AdaptiveShellRoute is supported; '
              'put more tabs in branches instead of nesting shells.',
            );
          }
          if (parentFullPath.isNotEmpty && parentFullPath != '/') {
            throw StateError(
              'ponytail: AdaptiveShellRoute must be a top-level route.',
            );
          }
          _shell = node;
          for (var i = 0; i < node.branches.length; i++) {
            _walk(node.branches[i].routes, parentFullPath: '', branchIndex: i);
          }
        case AdaptiveRoute():
          final fullPath = joinPaths(parentFullPath, node.path);
          if (node.name != null) {
            if (_named.containsKey(node.name)) {
              throw ArgumentError('Duplicate route name: ${node.name}');
            }
            _named[node.name!] = NamedRouteRef(
              route: node,
              fullPath: fullPath,
              pattern: PathPattern(fullPath),
              branchIndex: branchIndex,
            );
          }
          _walk(
            node.routes,
            parentFullPath: fullPath,
            branchIndex: branchIndex,
          );
      }
    }
  }

  /// 把命名路由 + 参数展开成 location。缺名或缺参抛 [ArgumentError]。
  ///
  /// [queryParameters] 的值会 `toString()` 后编码。
  String namedLocation(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  }) {
    final ref = _named[name];
    if (ref == null) {
      throw ArgumentError('Unknown route name: $name');
    }
    final path = ref.pattern.expand(pathParameters);
    if (queryParameters.isEmpty) return path;
    final query = <String, String>{
      for (final entry in queryParameters.entries)
        entry.key: entry.value.toString(),
    };
    return Uri(path: path, queryParameters: query).toString();
  }

  /// 按声明顺序匹配 [uri]。失败返回 [AdaptiveRouteMatchList.notFound]。
  AdaptiveRouteMatchList match(Uri uri, {Object? arguments}) {
    final result = _matchNodes(
      routes,
      uri.pathSegments,
      start: 0,
      params: const <String, String>{},
      parentFullPath: '',
      branchIndex: null,
      shell: null,
      prefix: const <AdaptiveRouteMatch>[],
      uri: uri,
      arguments: arguments,
    );
    return result ?? AdaptiveRouteMatchList.notFound(uri, arguments: arguments);
  }

  /// 从 [nodes] 顺序尝试匹配 [pathSegments] 的 [start] 起剩余段。
  AdaptiveRouteMatchList? _matchNodes(
    Iterable<AdaptiveRouteBase> nodes,
    List<String> pathSegments, {
    required int start,
    required Map<String, String> params,
    required String parentFullPath,
    required int? branchIndex,
    required AdaptiveShellRoute? shell,
    required List<AdaptiveRouteMatch> prefix,
    required Uri uri,
    required Object? arguments,
  }) {
    for (final node in nodes) {
      switch (node) {
        case AdaptiveShellRoute():
          for (var i = 0; i < node.branches.length; i++) {
            final nested = _matchNodes(
              node.branches[i].routes,
              pathSegments,
              start: start,
              params: params,
              parentFullPath: parentFullPath,
              branchIndex: i,
              shell: node,
              prefix: prefix,
              uri: uri,
              arguments: arguments,
            );
            if (nested != null) return nested;
          }
        case AdaptiveRoute():
          final hit = _matchRoute(
            node,
            pathSegments,
            start: start,
            params: params,
            parentFullPath: parentFullPath,
            branchIndex: branchIndex,
            shell: shell,
            prefix: prefix,
            uri: uri,
            arguments: arguments,
          );
          if (hit != null) return hit;
      }
    }
    return null;
  }

  /// 尝试本层 [route]，必要时递归子路由。剩余段无法消耗则返回 null。
  AdaptiveRouteMatchList? _matchRoute(
    AdaptiveRoute route,
    List<String> pathSegments, {
    required int start,
    required Map<String, String> params,
    required String parentFullPath,
    required int? branchIndex,
    required AdaptiveShellRoute? shell,
    required List<AdaptiveRouteMatch> prefix,
    required Uri uri,
    required Object? arguments,
  }) {
    final pattern = PathPattern(route.path);
    final pm = pattern.match(pathSegments, start: start);
    if (pm == null) return null;
    final consumedEnd = start + pm.consumed;
    final merged = <String, String>{...params, ...pm.params};
    final fullPath = joinPaths(parentFullPath, route.path);
    final matchedLocation = _matchedLocation(pathSegments, consumedEnd);
    final query = uri.queryParameters;
    final match = AdaptiveRouteMatch(
      route: route,
      matchedLocation: matchedLocation,
      fullPath: fullPath,
      pathParameters: merged,
      queryParameters: query,
      arguments: arguments,
      pageKey: ValueKey<String>(matchedLocation),
      title: signal(
        _titleFor(route, matchedLocation, fullPath, merged, query, arguments),
      ),
      branchIndex: route.onRootNavigator ? null : branchIndex,
    );
    final nextPrefix = [...prefix, match];
    if (consumedEnd == pathSegments.length) {
      return AdaptiveRouteMatchList(
        matches: nextPrefix,
        uri: uri,
        shell: shell,
        branchIndex: match.branchIndex ?? branchIndex,
        arguments: arguments,
      );
    }
    if (route.routes.isEmpty) {
      match.dispose();
      return null;
    }
    final nested = _matchNodes(
      route.routes,
      pathSegments,
      start: consumedEnd,
      params: merged,
      parentFullPath: fullPath,
      branchIndex: branchIndex,
      shell: shell,
      prefix: nextPrefix,
      uri: uri,
      arguments: arguments,
    );
    if (nested == null) {
      match.dispose();
    }
    return nested;
  }

  /// 前 [end] 段拼成 path；[end] 为 0 时返回 `/`。
  static String _matchedLocation(List<String> segments, int end) {
    if (end <= 0) return '/';
    return '/${segments.sublist(0, end).join('/')}';
  }

  /// [AdaptiveRoute.title] 或 path 末段 humanize。
  ///
  /// 给 builder 的 state 与 [AdaptiveRouteMatch.toState] 一致：
  /// [fullPath] 为完整模式（如 `/mail/:folder/:threadId`），`uri` 带 query。
  static String _titleFor(
    AdaptiveRoute route,
    String matchedLocation,
    String fullPath,
    Map<String, String> pathParameters,
    Map<String, String> queryParameters,
    Object? arguments,
  ) {
    if (route.title != null) {
      return route.title!(
        AdaptiveRouteState(
          uri: Uri(
            path: matchedLocation,
            queryParameters: queryParameters.isEmpty ? null : queryParameters,
          ),
          matchedLocation: matchedLocation,
          fullPath: fullPath,
          name: route.name,
          pathParameters: pathParameters,
          queryParameters: queryParameters,
          arguments: arguments,
          pageKey: ValueKey<String>(matchedLocation),
        ),
      );
    }
    return humanizePath(route.name ?? matchedLocation);
  }
}
