/// 路由 path 的一段：字面量或 `:name` 参数。
class PathSegment {
  /// 字面量段，例如 `mail`。
  const PathSegment.literal(this.literal) : paramName = null;

  /// 参数段，[paramName] 不含冒号。
  const PathSegment.param(this.paramName) : literal = null;

  /// 字面量；参数段为 null。
  final String? literal;

  /// 参数名；字面量段为 null。
  final String? paramName;

  /// 是否为 `:param`。
  bool get isParam => paramName != null;
}
