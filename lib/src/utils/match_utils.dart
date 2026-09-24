import '../router/adaptive_route_match.dart';

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
