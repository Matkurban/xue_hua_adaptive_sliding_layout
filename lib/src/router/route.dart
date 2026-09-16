import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/breadcrumbs.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/layout_breakpoints.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/pane_scope.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/sliding_pane_viewport.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/route_state.dart';

/// 把 [parent] 与 [child] 拼成完整 path 模式。
///
/// [child] 以 `/` 开头时视为绝对路径，忽略 [parent]。
/// [parent] 为 `/` 或空时结果为 `/child`（child 无前导斜杠）或 [child] 本身。
String joinPaths(String parent, String child) {
  if (child.startsWith('/')) return _normalizePath(child);
  final prefix = _normalizePath(parent);
  if (child.isEmpty) return prefix;
  if (prefix == '/') return '/$child';
  return '$prefix/$child';
}

/// 去掉末尾 `/`（根路径 `/` 除外）。
String _normalizePath(String path) {
  if (path.isEmpty) return '/';
  if (path == '/') return '/';
  if (path.endsWith('/')) return path.substring(0, path.length - 1);
  return path;
}

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

/// 一次 [PathPattern.match] 的结果：消耗了几段、抽出的参数。
class PathMatch {
  /// [consumed] 为匹配到的 segment 个数；[params] 为本层抽出的路径参数。
  const PathMatch({required this.consumed, required this.params});

  /// 从 start 起消耗的段数。
  final int consumed;

  /// 本层路径参数。
  final Map<String, String> params;
}

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

/// 页面工厂。第二参数是当前匹配快照。
typedef AdaptiveRouteBuilder =
    Widget Function(BuildContext context, AdaptiveRouteState state);

/// 壳层工厂。[child] 为当前分支的栏位 / Navigator。
typedef AdaptiveShellBuilder =
    Widget Function(
      BuildContext context,
      AdaptiveShellState shell,
      Widget child,
    );

/// 双栏右栏在深度不足时的占位。
typedef AdaptivePlaceholderBuilder = Widget Function(BuildContext context);

/// 返回非 null 的 location 则改去那里。可同步或异步。
typedef AdaptiveRedirect =
    FutureOr<String?> Function(
      BuildContext context,
      AdaptiveRouteState state,
    );

/// 返回 false 则取消这次离开（[AdaptiveRouter.maybePop] / 系统返回 / 浏览器后退）。
typedef AdaptiveOnExit =
    FutureOr<bool> Function(BuildContext context, AdaptiveRouteState state);

/// 入栈时的面包屑 / 栏标题。
typedef AdaptiveTitleBuilder = String Function(AdaptiveRouteState state);

/// 自定义过场，签名与 [PageRouteBuilder.transitionsBuilder] 相同。
typedef AdaptiveTransitionsBuilder =
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    );

/// 路由表节点：普通页或壳层。
sealed class AdaptiveRouteBase {
  /// 子类提供 const 构造。
  const AdaptiveRouteBase();
}

/// 一张页面路由。子 [routes] 的 path 为相对路径，`:param` 语法与 go_router 相同。
///
/// [builder] 与 [redirect] 至少提供一个。顺序优先：列表里先写的先匹配。
class AdaptiveRoute extends AdaptiveRouteBase {
  /// [path] 为 `/mail` 或相对 `:id`；[name] 供 [AdaptiveRouter.namedLocation] 使用。
  AdaptiveRoute({
    required this.path,
    this.name,
    this.builder,
    this.title,
    this.fullscreen = false,
    this.fullscreenDialog = false,
    this.opaque = true,
    this.barrierColor,
    this.barrierDismissible = false,
    this.transitionsBuilder,
    this.transitionDuration,
    this.redirect,
    this.onExit,
    this.routes = const <AdaptiveRoute>[],
  }) : assert(
         builder != null || redirect != null,
         'AdaptiveRoute($path) needs a builder or redirect',
       ),
       assert(path.isNotEmpty, 'AdaptiveRoute path must not be empty');

  /// 本层 path 模式。以 `/` 开头为绝对，否则拼到父 path 后面。
  final String path;

  /// 可选稳定名，给 [AdaptiveRouter.namedLocation] 用。全局不可重复。
  final String? name;

  /// 构建本页 Widget。redirect-only 路由可为 null。
  final AdaptiveRouteBuilder? builder;

  /// 入栈时的栏标题；缺省由 path / name humanize。
  final AdaptiveTitleBuilder? title;

  /// 为 true 时叠在根 Navigator 上，不进入滑动栏。
  final bool fullscreen;

  /// 根 Navigator 上按全屏对话框呈现（[MaterialPage.fullscreenDialog]）。
  final bool fullscreenDialog;

  /// 有 [transitionsBuilder] 时传给 [PageRouteBuilder.opaque]。默认不透明。
  final bool opaque;

  /// 有 [transitionsBuilder] 时的屏障色；透明覆盖层常用半透明黑。
  final Color? barrierColor;

  /// 有 [transitionsBuilder] 时点击屏障是否弹出。
  final bool barrierDismissible;

  /// 根 Navigator 上的自定义过场；栏内页忽略（栏位是并排的）。
  final AdaptiveTransitionsBuilder? transitionsBuilder;

  /// [transitionsBuilder] 的时长，默认 300ms。
  final Duration? transitionDuration;

  /// 匹配到本路由后、入栈前的 redirect。
  final AdaptiveRedirect? redirect;

  /// [AdaptiveRouter.maybePop] 等询问式离开时调用。
  final AdaptiveOnExit? onExit;

  /// 相对路径子路由，顺序优先匹配。
  final List<AdaptiveRoute> routes;
}

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
    return _normalizePath(normalized);
  }
}

/// 多分支壳：宽度决定 1 栏 Navigator 还是 2 栏滑动视口。
///
/// `ponytail:` 整棵路由树只允许一个本类型，出现在顶层。嵌套壳需要另开分支模型。
class AdaptiveShellRoute extends AdaptiveRouteBase {
  /// [builder] 画 rail / bottom bar；[branches] 为各 Tab 的路由树。
  AdaptiveShellRoute({
    required this.builder,
    required this.branches,
    this.breakpoints = const LayoutBreakpoints(),
    this.showBreadcrumbs = true,
    this.resizable = true,
    this.initialLeftPaneFraction = 0.5,
    this.minLeftPaneFraction = 0.3,
    this.minRightPaneFraction = 0.3,
    this.onLeftPaneFractionChanged,
    this.breadcrumbsBuilder,
    this.placeholder,
    this.paneBuilder,
    this.resizeHandleBuilder,
    this.slideDuration = SlidingPaneViewport.defaultSlideDuration,
    this.slideCurve = SlidingPaneViewport.defaultSlideCurve,
    this.escapePops = true,
  }) : assert(branches.isNotEmpty, 'AdaptiveShellRoute.branches must not be empty');

  /// 宿主壳 UI。必须把 [child] 放到内容区。
  final AdaptiveShellBuilder builder;

  /// 各 Tab。按声明顺序对应 [AdaptiveShellState.currentIndex]。
  final List<AdaptiveBranch> branches;

  /// 栏数断点。
  final LayoutBreakpoints breakpoints;

  /// expanded 下是否在视口上方画整栈面包屑。
  final bool showBreadcrumbs;

  /// 双栏时是否显示分割条。
  final bool resizable;

  /// 左栏初始比例。
  final double initialLeftPaneFraction;

  /// 左栏最小比例。
  final double minLeftPaneFraction;

  /// 右栏最小比例（决定左栏上限）。
  final double minRightPaneFraction;

  /// 分割条松手时的新比例。
  final ValueChanged<double>? onLeftPaneFractionChanged;

  /// 非空时替换默认 [AdaptiveBreadcrumbs]；仍受 [showBreadcrumbs] 控制。
  final AdaptiveBreadcrumbsBuilder? breadcrumbsBuilder;

  /// 壳级默认右栏占位。[AdaptiveBranch.placeholder] 优先。
  final AdaptivePlaceholderBuilder? placeholder;

  /// 包每一栏；透传到 [SlidingPaneViewport.paneBuilder]。
  final SlidingPaneFrameBuilder? paneBuilder;

  /// 只换分割条视觉；透传到 [SlidingPaneViewport.resizeHandleBuilder]。
  final WidgetBuilder? resizeHandleBuilder;

  /// 栏位平移动画时长。
  final Duration slideDuration;

  /// 栏位平移动画曲线。
  final Curve slideCurve;

  /// 为 false 时 Escape 不再调用 [AdaptiveRouter.maybePop]。
  final bool escapePops;
}
