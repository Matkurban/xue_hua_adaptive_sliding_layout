import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/route.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/route_state.dart';

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

/// 一次导航的完整匹配结果：当前分支栈 + 根上的覆盖层。
class AdaptiveRouteMatchList {
  /// [matches] 为顺序页面栈（先分支页，后覆盖层）。
  AdaptiveRouteMatchList({
    required this.matches,
    required this.uri,
    this.shell,
    this.branchIndex,
    this.arguments,
    this.error,
  });

  /// 无路由命中时的空栈。
  factory AdaptiveRouteMatchList.notFound(
    Uri uri, {
    Object? arguments,
  }) {
    return AdaptiveRouteMatchList(
      matches: const <AdaptiveRouteMatch>[],
      uri: uri,
      arguments: arguments,
      error: Exception('No routes for ${uri.path}'),
    );
  }

  /// 从根到顶的匹配，覆盖层排在分支页之后。
  final List<AdaptiveRouteMatch> matches;

  /// 当前应写入浏览器的 location。
  final Uri uri;

  /// 命中的壳；纯覆盖层（如 `/login` 深链）为 null。
  final AdaptiveShellRoute? shell;

  /// 当前分支下标。
  final int? branchIndex;

  /// 本次导航的 [arguments]。
  final Object? arguments;

  /// 未匹配或 redirect 循环。
  final Exception? error;

  /// 当前分支内的页（非 overlay）。
  List<AdaptiveRouteMatch> get branchMatches {
    return [
      for (final match in matches)
        if (!match.isOverlay) match,
    ];
  }

  /// 叠在根 Navigator 上的页。
  List<AdaptiveRouteMatch> get overlayMatches {
    return [
      for (final match in matches)
        if (match.isOverlay) match,
    ];
  }

  /// 栈顶匹配。
  AdaptiveRouteMatch? get last => matches.isEmpty ? null : matches.last;

  /// 是否还能弹出：覆盖层下还有页，或覆盖层多于 1，或分支深度大于 1。
  bool get canPop {
    final overlays = overlayMatches;
    final branch = branchMatches;
    if (overlays.length > 1) return true;
    if (overlays.length == 1 && branch.isNotEmpty) return true;
    return branch.length > 1;
  }

  /// 用新栈 / uri 复制。
  AdaptiveRouteMatchList copyWith({
    List<AdaptiveRouteMatch>? matches,
    Uri? uri,
    AdaptiveShellRoute? shell,
    int? branchIndex,
    Object? arguments,
    Exception? error,
    bool clearError = false,
  }) {
    return AdaptiveRouteMatchList(
      matches: matches ?? this.matches,
      uri: uri ?? this.uri,
      shell: shell ?? this.shell,
      branchIndex: branchIndex ?? this.branchIndex,
      arguments: arguments ?? this.arguments,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 已编译的命名路由：全路径模式 + 所属分支。
class NamedRouteRef {
  /// [fullPath] 为 `/mail/:folder/:id`；[branchIndex] 壳外为 null。
  const NamedRouteRef({
    required this.route,
    required this.fullPath,
    required this.pattern,
    this.branchIndex,
  });

  /// 表项。
  final AdaptiveRoute route;

  /// 拼接后的完整模式。
  final String fullPath;

  /// 用于 [PathPattern.expand]。
  final PathPattern pattern;

  /// 所属分支。
  final int? branchIndex;
}

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
            _walk(
              node.branches[i].routes,
              parentFullPath: '',
              branchIndex: i,
            );
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
      title: signal(_titleFor(route, matchedLocation, merged, query, arguments)),
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
  static String _titleFor(
    AdaptiveRoute route,
    String matchedLocation,
    Map<String, String> pathParameters,
    Map<String, String> queryParameters,
    Object? arguments,
  ) {
    if (route.title != null) {
      return route.title!(
        AdaptiveRouteState(
          uri: Uri.parse(matchedLocation),
          matchedLocation: matchedLocation,
          fullPath: route.path,
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

/// 把 path 或 widget 名变成可读标题：去掉 `/`、`:params`、末尾 `Page`/`View`，驼峰插空格。
String humanizePath(String name) {
  if (name.startsWith('/')) {
    final parts = name
        .split('/')
        .where((part) => part.isNotEmpty && !part.startsWith(':'))
        .toList();
    if (parts.isNotEmpty) return _humanize(parts.last);
  }
  final stripped = name.replaceAll(RegExp(r'(Page|View)$'), '');
  if (stripped.isNotEmpty && stripped != name) return _humanize(stripped);
  return _humanize(name);
}

String _humanize(String raw) {
  final spaced = raw.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match[1]} ${match[2]}',
  );
  if (spaced.isEmpty) return raw;
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

/// 判断 [current] 的 [matchedLocation] 序列是否为 [target] 的前缀（含相等）。
bool isMatchPrefix(
  List<AdaptiveRouteMatch> current,
  List<AdaptiveRouteMatch> target,
) {
  if (current.length > target.length) return false;
  for (var i = 0; i < current.length; i++) {
    if (current[i].matchedLocation != target[i].matchedLocation) {
      return false;
    }
  }
  return true;
}

/// 复用 [current] 中与 [target] 相同 location 的前缀，后缀用 [target] 的新 match。
///
/// 被跳过的 [target] 前缀会 [AdaptiveRouteMatch.dispose]，避免 title signal 泄漏。
List<AdaptiveRouteMatch> reusePrefixMatches(
  List<AdaptiveRouteMatch> current,
  List<AdaptiveRouteMatch> target,
) {
  final result = <AdaptiveRouteMatch>[];
  for (var i = 0; i < target.length; i++) {
    if (i < current.length &&
        current[i].matchedLocation == target[i].matchedLocation) {
      target[i].dispose();
      result.add(current[i]);
    } else {
      result.add(target[i]);
    }
  }
  return result;
}

/// 丢掉 [oldList] 中不在 [newList] 里的 match（按 [AdaptiveRouteMatch.pageKey]）。
void disposeDroppedMatches(
  AdaptiveRouteMatchList oldList,
  AdaptiveRouteMatchList newList, [
  Object? result,
]) {
  final kept = <Key>{for (final match in newList.matches) match.pageKey};
  for (final match in oldList.matches) {
    if (!kept.contains(match.pageKey)) {
      match.dispose(result);
    }
  }
}
