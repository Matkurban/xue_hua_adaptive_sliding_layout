import 'path_match.dart';
import 'path_segment.dart';

/// 编译 `/mail/:folder/:threadId` 这类模式，按段匹配。
class PathPattern {
  /// [pattern] 为路由表中的 path（可相对、可绝对）。
  PathPattern(this.pattern) : segments = _parse(pattern);

  /// 原始模式字符串。
  final String pattern;

  /// 去掉前导 `/` 后按 `/` 切开的段。
  final List<PathSegment> segments;

  /// 把模式拆成 [PathSegment]。`/` 或空串得到空列表（只匹配空 path）。
  static List<PathSegment> _parse(String pattern) {
    var raw = pattern;
    if (raw.startsWith('/')) raw = raw.substring(1);
    if (raw.endsWith('/')) raw = raw.substring(0, raw.length - 1);
    if (raw.isEmpty) return const <PathSegment>[];
    return [
      for (final part in raw.split('/'))
        part.startsWith(':') && part.length > 1
            ? PathSegment.param(part.substring(1))
            : PathSegment.literal(part),
    ];
  }

  /// 从 [pathSegments] 的 [start] 起尝试匹配。失败返回 null。
  ///
  /// 空模式（`/`）仅当 [start] 为 0 且 [pathSegments] 为空时成功，消耗 0 段。
  PathMatch? match(List<String> pathSegments, {int start = 0}) {
    if (segments.isEmpty) {
      if (start == 0 && pathSegments.isEmpty) {
        return const PathMatch(consumed: 0, params: <String, String>{});
      }
      return null;
    }
    if (start + segments.length > pathSegments.length) return null;
    final params = <String, String>{};
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final value = pathSegments[start + i];
      if (seg.isParam) {
        params[seg.paramName!] = Uri.decodeComponent(value);
      } else if (seg.literal != value) {
        return null;
      }
    }
    return PathMatch(consumed: segments.length, params: params);
  }

  /// 用 [pathParameters] 把模式填成具体 path。缺参抛 [ArgumentError]。
  String expand(Map<String, String> pathParameters) {
    if (segments.isEmpty) return '/';
    final parts = <String>[];
    for (final seg in segments) {
      if (seg.isParam) {
        final value = pathParameters[seg.paramName];
        if (value == null) {
          throw ArgumentError('Missing path parameter :${seg.paramName}');
        }
        parts.add(Uri.encodeComponent(value));
      } else {
        parts.add(seg.literal!);
      }
    }
    return '/${parts.join('/')}';
  }
}
