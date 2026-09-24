import 'adaptive_route.dart';
import 'path_pattern.dart';

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
