import 'adaptive_route_match.dart';
import 'adaptive_shell_route.dart';

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
  factory AdaptiveRouteMatchList.notFound(Uri uri, {Object? arguments}) {
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
