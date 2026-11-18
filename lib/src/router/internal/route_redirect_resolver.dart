import 'package:flutter/foundation.dart' show SynchronousFuture;
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
  ///
  /// 所有命中的 redirect 均为同步返回（或未配置）时返回 [SynchronousFuture]，
  /// 使 Flutter [Router] 能在首帧 `build()` 之前同步完成初始路由解析。
  Future<AdaptiveRouteMatchList> resolve(
    BuildContext context,
    Uri uri, {
    Object? arguments,
  }) {
    return _resolveFrom(context, uri, 0, arguments: arguments);
  }

  Future<AdaptiveRouteMatchList> _resolveFrom(
    BuildContext context,
    Uri uri,
    int startHop, {
    Object? arguments,
  }) {
    var current = uri;
    for (var hop = startHop; hop < redirectLimit; hop++) {
      if (!context.mounted) {
        return SynchronousFuture<AdaptiveRouteMatchList>(
          registry.match(current, arguments: arguments),
        );
      }
      final matched = registry.match(current, arguments: arguments);
      final state = stateFor(matched, current);
      final top = redirect?.call(context, state);
      if (top is Future<String?>) {
        return _continueAfterTopRedirect(
          context,
          current,
          hop,
          matched,
          top,
          arguments: arguments,
        );
      }
      if (top != null && !_sameLocation(current, top)) {
        disposeMatches(matched.matches);
        current = parseLocation(top);
        continue;
      }
      if (!context.mounted) {
        return SynchronousFuture<AdaptiveRouteMatchList>(matched);
      }
      var redirected = false;
      for (var i = 0; i < matched.matches.length; i++) {
        if (!context.mounted) {
          return SynchronousFuture<AdaptiveRouteMatchList>(matched);
        }
        final match = matched.matches[i];
        final next = match.route.redirect?.call(
          context,
          match.toState(current, error: matched.error),
        );
        if (next is Future<String?>) {
          return _continueAfterRouteRedirect(
            context,
            current,
            hop,
            matched,
            i,
            next,
            arguments: arguments,
          );
        }
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
      return SynchronousFuture<AdaptiveRouteMatchList>(matched);
    }
    return SynchronousFuture<AdaptiveRouteMatchList>(
      AdaptiveRouteMatchList(
        matches: const <AdaptiveRouteMatch>[],
        uri: current,
        error: Exception('Redirect loop after $redirectLimit hops'),
      ),
    );
  }

  Future<AdaptiveRouteMatchList> _continueAfterTopRedirect(
    BuildContext context,
    Uri current,
    int hop,
    AdaptiveRouteMatchList matched,
    Future<String?> topFuture, {
    Object? arguments,
  }) async {
    final top = await topFuture;
    if (top != null && !_sameLocation(current, top)) {
      disposeMatches(matched.matches);
      final nextUri = parseLocation(top);
      if (!context.mounted) {
        return registry.match(nextUri, arguments: arguments);
      }
      return _resolveFrom(context, nextUri, hop + 1, arguments: arguments);
    }
    if (!context.mounted) {
      return matched;
    }
    return _continueRouteRedirects(
      context,
      current,
      hop,
      matched,
      0,
      arguments: arguments,
    );
  }

  Future<AdaptiveRouteMatchList> _continueAfterRouteRedirect(
    BuildContext context,
    Uri current,
    int hop,
    AdaptiveRouteMatchList matched,
    int index,
    Future<String?> nextFuture, {
    Object? arguments,
  }) async {
    final next = await nextFuture;
    if (next != null && !_sameLocation(current, next)) {
      disposeMatches(matched.matches);
      final nextUri = parseLocation(next);
      if (!context.mounted) {
        return registry.match(nextUri, arguments: arguments);
      }
      return _resolveFrom(context, nextUri, hop + 1, arguments: arguments);
    }
    if (!context.mounted) {
      return matched;
    }
    return _continueRouteRedirects(
      context,
      current,
      hop,
      matched,
      index + 1,
      arguments: arguments,
    );
  }

  Future<AdaptiveRouteMatchList> _continueRouteRedirects(
    BuildContext context,
    Uri current,
    int hop,
    AdaptiveRouteMatchList matched,
    int startIndex, {
    Object? arguments,
  }) async {
    for (var i = startIndex; i < matched.matches.length; i++) {
      if (!context.mounted) return matched;
      final match = matched.matches[i];
      final next = await match.route.redirect?.call(
        context,
        match.toState(current, error: matched.error),
      );
      if (next != null && !_sameLocation(current, next)) {
        disposeMatches(matched.matches);
        final nextUri = parseLocation(next);
        if (!context.mounted) {
          return registry.match(nextUri, arguments: arguments);
        }
        return _resolveFrom(context, nextUri, hop + 1, arguments: arguments);
      }
    }
    return matched;
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
