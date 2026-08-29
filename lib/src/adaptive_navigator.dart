import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_page_title.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_window_controller.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_window_page.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_window_scope.dart';

/// 命名路由构造参数（宿主自行映射到页面）。
class AdaptiveRouteArgs {
  /// [name] 为宿主登记的路由 id；其余字段来自对应的 `pushNamed*` 实参。
  const AdaptiveRouteArgs({
    required this.name,
    this.extra,
    this.pathParameters = const <String, String>{},
    this.queryParameters = const <String, String>{},
  });

  /// 路由 id（如 `/thread/:id` 或 `chat`），与 [AdaptiveNavigator.handlesRoute] 对照。
  final String name;

  /// `pushNamed(..., extra:)` 带来的不透明对象，原样交给 [AdaptiveNavigator.buildPage]。
  final Object? extra;

  /// 路径参数，例如 `{'id': '12'}`。
  final Map<String, String> pathParameters;

  /// 已转成字符串的 query（[AdaptiveNavigator] 会对 dynamic 做 `toString()`）。
  final Map<String, String> queryParameters;
}

/// 宽屏未处理时的窄屏 / 根导航回落。方法与 [AdaptiveNavigator] 成对。
///
/// 宿主用现有 `Navigator` 或 GoRouter 实现；滑动栈的 `predicate` 在窄屏上通常无意义。
abstract class AdaptiveNavigatorFallback {
  /// 压入一页。有 [from] 时尽量用该 context 的 Navigator。
  Future<T?> push<T extends Object?>(Widget page, {BuildContext? from});

  /// 按名字压入。典型实现：`context.pushNamed` 或自己构图再 [push]。
  Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  });

  /// 替换当前路由。典型实现：`Navigator.pushReplacement`。
  Future<T?> pushReplacement<T extends Object?>(
    Widget page, {
    BuildContext? from,
  });

  /// 按名字替换。GoRouter 宿主通常接到 `context.goNamed`。
  Future<T?> pushReplacementNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
    String? fragment,
  });

  /// 弹出到谓词再压入。窄屏常映射成 [pushReplacement]（没有滑动栈）。
  Future<T?> pushAndRemoveUntil<T extends Object?>(
    Widget page,
    bool Function(SlidingWindowPage page) predicate, {
    BuildContext? from,
  });

  /// 命名版 [pushAndRemoveUntil]。窄屏常映射成 [pushNamed] 或 [pushReplacementNamed]。
  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String name,
    bool Function(SlidingWindowPage page) predicate, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  });

  /// 弹出当前宿主导航栈顶。
  void pop<T extends Object?>([T? result]);

  /// 宿主导航是否还能 pop。
  bool canPop();

  /// 宿主导航弹到第一页。成功动手返回 true。
  bool popToRoot();
}

/// 通用宽屏导航：窄屏走 [fallback]，宽屏写入当前 Tab 滑动栈。
///
/// 动词与 Flutter [Navigator] 成对：有 [push] 必有 [pushNamed]，以此类推。
/// `from` 只出现在 [push] / [pushNamed]，表示从哪一栏压。
class AdaptiveNavigator {
  /// 用宿主的断点、当前栈、页面工厂和回落导航构造。
  AdaptiveNavigator({
    required this.isSlidingActive,
    required this.currentStack,
    required this.buildPage,
    required this.handlesRoute,
    required this.fallback,
    this.resolveTitle,
  });

  /// [SlidingWindowController.ensureRoot] 写入的根页 key。
  static const Key rootPageKey = ValueKey<String>('sliding-root');

  /// 供 [pushAndRemoveUntil] / [pushNamedAndRemoveUntil] 停在根页。
  static bool untilRoot(SlidingWindowPage page) => page.key == rootPageKey;

  /// 宽屏滑动是否开启。为 false 时全部动词走 [fallback]。
  final bool Function() isSlidingActive;

  /// 当前 Tab 的栈。切 Tab 后应返回另一个 [SlidingWindowController]。
  final SlidingWindowController Function() currentStack;

  /// 把 [AdaptiveRouteArgs] 映射成 Widget；返回 null 则改走 [fallback]。
  final Widget? Function(AdaptiveRouteArgs args) buildPage;

  /// 宽屏下该命名路由是否进入滑动栈。
  final bool Function(String name) handlesRoute;

  /// 窄屏或 [handlesRoute] 为 false 时的根导航。
  final AdaptiveNavigatorFallback fallback;

  /// 入栈时的面包屑 / 页标题。缺省 [SlidingPageTitle.humanize]。
  final String Function(String name)? resolveTitle;

  /// 压入一页。有 [from] 时按栏 [SlidingWindowController.openAfter]。
  Future<T?> push<T extends Object?>(
    Widget page, {
    String name = '',
    String? title,
    BuildContext? from,
  }) {
    if (isSlidingActive()) {
      return _commitPush<T>(
        page,
        name: name,
        title: title,
        fromPaneIndex: from == null
            ? null
            : SlidingPaneScope.maybeOf(from)?.index,
      );
    }
    return fallback.push<T>(page, from: from);
  }

  /// [from] 有值时按栏分流；无 [from] 时压栈。
  ///
  /// 未开启滑动或 [handlesRoute] 为 false，或 [buildPage] 返回 null 时走 [fallback.pushNamed]。
  Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
    BuildContext? from,
  }) {
    final page = _tryHandlePage(
      name: name,
      extra: extra,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
    );
    if (page != null) {
      return _commitPush<T>(
        page,
        name: name,
        fromPaneIndex: from == null
            ? null
            : SlidingPaneScope.maybeOf(from)?.index,
      );
    }
    return fallback.pushNamed<T>(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// 只换栈顶。
  Future<T?> pushReplacement<T extends Object?>(
    Widget page, {
    String name = '',
    String? title,
  }) {
    if (!isSlidingActive()) {
      return fallback.pushReplacement<T>(page);
    }
    return _replaceSliding<T>(page, name: name, title: title);
  }

  /// 只换栈顶。窄屏回落为 [AdaptiveNavigatorFallback.pushReplacementNamed]。
  Future<T?> pushReplacementNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
    String? fragment,
  }) {
    if (!isSlidingActive() || !handlesRoute(name)) {
      return fallback.pushReplacementNamed<T>(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
        fragment: fragment,
      );
    }
    final page = buildPage(
      _argsFor(
        name: name,
        extra: extra,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
      ),
    );
    if (page == null) {
      return fallback.pushReplacementNamed<T>(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
        fragment: fragment,
      );
    }
    return _replaceSliding<T>(page, name: name);
  }

  /// 弹出到 [predicate] 为 true 的页再压入。到根时栈为 `[根, page]`。
  Future<T?> pushAndRemoveUntil<T extends Object?>(
    Widget page,
    bool Function(SlidingWindowPage page) predicate, {
    String name = '',
    String? title,
  }) {
    if (!isSlidingActive()) {
      return fallback.pushAndRemoveUntil<T>(page, predicate);
    }
    return _commitRemoveUntil<T>(page, predicate, name: name, title: title);
  }

  /// 命名版 [pushAndRemoveUntil]。未拦截时走 [fallback.pushNamedAndRemoveUntil]。
  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String name,
    bool Function(SlidingWindowPage page) predicate, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    final page = _tryHandlePage(
      name: name,
      extra: extra,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
    );
    if (page == null) {
      return fallback.pushNamedAndRemoveUntil<T>(
        name,
        predicate,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      );
    }
    return _commitRemoveUntil<T>(page, predicate, name: name);
  }

  /// 滑动栈能弹则弹滑动栈，否则 [fallback.pop]。
  void pop<T extends Object?>([T? result]) {
    if (_popSliding<T>(result)) return;
    fallback.pop<T>(result);
  }

  /// 滑动栈或 fallback 任一还能 pop 则为 true。
  bool canPop() {
    if (isSlidingActive() && currentStack().canPop) {
      return true;
    }
    return fallback.canPop();
  }

  /// 弹出当前滑动栈至根页；窄屏回落为 [AdaptiveNavigatorFallback.popToRoot]。
  bool popToRoot() {
    if (_popSlidingToRoot()) return true;
    if (isSlidingActive()) return false;
    return fallback.popToRoot();
  }

  /// 宿主 [resolveTitle] 或 [SlidingPageTitle.humanize]。
  String _titleFor(String name) =>
      resolveTitle?.call(name) ?? SlidingPageTitle.humanize(name);

  /// 把 query 的 dynamic 值转成 String，写入 [AdaptiveRouteArgs]。
  static Map<String, String> _stringifyQuery(Map<String, dynamic> query) {
    return query.map((key, value) => MapEntry(key, value.toString()));
  }

  /// 组装 [buildPage] 所需参数。
  AdaptiveRouteArgs _argsFor({
    required String name,
    Object? extra,
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  }) {
    return AdaptiveRouteArgs(
      name: name,
      extra: extra,
      pathParameters: pathParameters,
      queryParameters: _stringifyQuery(queryParameters),
    );
  }

  /// 宽屏且 [handlesRoute] 且 [buildPage] 非空时返回页面，否则 null（改走 fallback）。
  Widget? _tryHandlePage({
    required String name,
    Object? extra,
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  }) {
    if (!isSlidingActive() || !handlesRoute(name)) return null;
    return buildPage(
      _argsFor(
        name: name,
        extra: extra,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
      ),
    );
  }

  /// 有 [fromPaneIndex] 时 [openAfter]（同名则跳回），否则 [SlidingWindowController.push]。
  Future<T?> _commitPush<T extends Object?>(
    Widget page, {
    required String name,
    String? title,
    int? fromPaneIndex,
  }) {
    final label = name.isEmpty ? page.runtimeType.toString() : name;
    final resolvedTitle = title ?? _titleFor(label);
    final stack = currentStack();
    if (fromPaneIndex != null) {
      final keepCount = fromPaneIndex + 1;
      final existing = stack.indexOfName(label);
      if (existing >= keepCount) {
        return stack.openAfter<T>(
          existing,
          (_) => page,
          name: label,
          title: resolvedTitle,
        );
      }
      return stack.openAfter<T>(
        keepCount,
        (_) => page,
        name: label,
        title: resolvedTitle,
      );
    }
    return stack.push<T>((_) => page, name: label, title: resolvedTitle);
  }

  /// 只换当前 Tab 栈顶。
  Future<T?> _replaceSliding<T extends Object?>(
    Widget page, {
    required String name,
    String? title,
  }) {
    final label = name.isEmpty ? page.runtimeType.toString() : name;
    return currentStack().replace<T>(
      (_) => page,
      name: label,
      title: title ?? _titleFor(label),
    );
  }

  /// 先 [SlidingWindowController.popUntil]，再 [SlidingWindowController.push]。
  Future<T?> _commitRemoveUntil<T extends Object?>(
    Widget page,
    bool Function(SlidingWindowPage page) predicate, {
    required String name,
    String? title,
  }) {
    final label = name.isEmpty ? page.runtimeType.toString() : name;
    final resolvedTitle = title ?? _titleFor(label);
    final stack = currentStack();
    stack.popUntil(predicate);
    return stack.push<T>((_) => page, name: label, title: resolvedTitle);
  }

  /// 滑动开启且能弹时 pop 并返回 true，否则 false（调用方改走 fallback）。
  bool _popSliding<T extends Object?>([T? result]) {
    if (!isSlidingActive()) return false;
    final stack = currentStack();
    if (!stack.canPop) return false;
    return stack.pop<T>(result);
  }

  /// 滑动开启且能弹时 [popToRoot] 并返回 true。已在根或未开启则 false。
  bool _popSlidingToRoot() {
    if (!isSlidingActive()) return false;
    final stack = currentStack();
    if (!stack.canPop) return false;
    stack.popToRoot();
    return true;
  }
}
