import 'package:flutter/widgets.dart';

import '../utils/path_utils.dart';
import 'adaptive_route.dart';

/// 双栏右栏在深度不足时的占位。
typedef AdaptivePlaceholderBuilder = Widget Function(BuildContext context);

/// 一个 Tab 分支：一组以绝对 path 开头的路由树。
class AdaptiveBranch {
  /// [routes] 通常以 `/mail` 这类绝对 path 起头。
  ///
  /// [initialLocation] 缺省为第一条路由展开后的 path（不含参数的字面量）。
  AdaptiveBranch({
    required this.routes,
    String? initialLocation,
    this.placeholder,
  }) : assert(routes.isNotEmpty, 'AdaptiveBranch.routes must not be empty'),
       initialLocation = initialLocation ?? _literalPath(routes.first.path);

  /// 本分支的路由树。
  final List<AdaptiveRoute> routes;

  /// 首次进入或 [AdaptiveShellState.goBranch] `initialLocation: true` 时的 location。
  final String initialLocation;

  /// 双栏且本分支深度为 1 时右栏空态。
  final AdaptivePlaceholderBuilder? placeholder;

  /// 无参数时用路由 path 当初始 location（`/mail`）；含 `:param` 的由调用方显式传入。
  static String _literalPath(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    if (normalized.contains(':')) {
      throw ArgumentError(
        'AdaptiveBranch.initialLocation is required when the first path '
        'contains parameters: $path',
      );
    }
    return normalizePath(normalized);
  }
}
