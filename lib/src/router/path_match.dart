/// 一次 [PathPattern.match] 的结果：消耗了几段、抽出的参数。
class PathMatch {
  /// [consumed] 为匹配到的 segment 个数；[params] 为本层抽出的路径参数。
  const PathMatch({required this.consumed, required this.params});

  /// 从 start 起消耗的段数。
  final int consumed;

  /// 本层路径参数。
  final Map<String, String> params;
}


