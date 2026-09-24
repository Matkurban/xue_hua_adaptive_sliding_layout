/// 把 [parent] 与 [child] 拼成完整 path 模式。
///
/// [child] 以 `/` 开头时视为绝对路径，忽略 [parent]。
/// [parent] 为 `/` 或空时结果为 `/child`（child 无前导斜杠）或 [child] 本身。
String joinPaths(String parent, String child) {
  if (child.startsWith('/')) return normalizePath(child);
  final prefix = normalizePath(parent);
  if (child.isEmpty) return prefix;
  if (prefix == '/') return '/$child';
  return '$prefix/$child';
}

/// 去掉末尾 `/`（根路径 `/` 除外）。
String normalizePath(String path) {
  if (path.isEmpty) return '/';
  if (path == '/') return '/';
  if (path.endsWith('/')) return path.substring(0, path.length - 1);
  return path;
}
