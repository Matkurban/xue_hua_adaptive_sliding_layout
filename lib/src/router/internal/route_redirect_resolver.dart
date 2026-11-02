import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match_list.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_state.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/route_registry.dart';

/// 负责解析 URI 并按序执行顶层及路由级 `redirect` 守卫。
class RouteRedirectResolver {
  const RouteRedirectResolver({
    required this.registry,
    required this.redirect,
    required this.redirectLimit,
  });

  final RouteRegistry registry;
  final AdaptiveRedirect? redirect;
  final int redirectLimit;

  /// 解析 [uri] 并跑顶层 / 路由级 redirect。
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
      final state = stateFor(matched, current);
      final top = await redirect?.call(context, state);
      if (top != null && !_sameLocation(current, top)) {
        disposeMatches(matched.matches);
        current = parseLocation(top);
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
          current = parseLocation(next);
          redirected = true;
          break;
        }
      }
      if (redirected) {
        disposeMatches(matched.matches);
        continue;
      }
      return matched;
    }
    return AdaptiveRouteMatchList(
      matches: const <AdaptiveRouteMatch>[],
      uri: current,
      error: Exception('Redirect loop after $redirectLimit hops'),
    );
  }

  /// 将匹配结果 [list] 转换为顶层 redirect 或错误页使用的 [AdaptiveRouteState]。
  static AdaptiveRouteState stateFor(AdaptiveRouteMatchList list, Uri uri) {
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

  static void disposeMatches(Iterable<AdaptiveRouteMatch> matches) {
    for (final match in matches) {
      match.dispose();
    }
  }

  static Uri parseLocation(String routeName) {
    if (!routeName.startsWith('/')) return Uri.parse('/$routeName');
    return Uri.parse(routeName);
  }

  static String formatLocation(Uri uri) {
    if (uri.hasQuery) return '${uri.path}?${uri.query}';
    return uri.path.isEmpty ? '/' : uri.path;
  }

  static bool _sameLocation(Uri uri, String other) {
    final parsed = parseLocation(other);
    return uri.path == parsed.path && uri.query == parsed.query;
  }
}
