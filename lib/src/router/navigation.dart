import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/match.dart';

/// 纯栈运算：把 Navigator 同名动词作用在 [AdaptiveRouteMatchList] 上。
///
/// [AdaptiveRouter] 在跑完 redirect / onExit 之后调用本类；测试可直接喂 MatchList。
/// 除 pop / 替换掉的页、被丢掉的覆盖层、以及 `registry.match` 产生的重复前缀外，
/// 不销毁当前分支栈（切 Tab 时由路由器保存在 [_branchStacks]）。
class NavigationEngine {
  /// [registry] 提供 URI 匹配。
  NavigationEngine(this.registry);

  /// 编译好的路由表。
  final RouteRegistry registry;

  int _imperativeId = 0;

  /// 测试或路由器重置时把命令式序号清零。
  void resetImperativeIds() => _imperativeId = 0;

  /// 与 [Navigator.pushNamed] 对齐的三条规则，见方案「导航动词」。
  AdaptiveRouteMatchList pushNamed(
    AdaptiveRouteMatchList current,
    String routeName, {
    Object? arguments,
  }) {
    final uri = _parse(routeName);
    final target = registry.match(uri, arguments: arguments);
    if (target.error != null) return target;

    if (_isOverlayTarget(target)) {
      return _pushOverlay(current, target, uri, arguments);
    }

    final targetBranch = target.branchIndex!;
    if (current.shell != null &&
        current.branchIndex != null &&
        current.branchIndex != targetBranch) {
      _disposeOverlays(current);
      return target;
    }

    final currentBranch = current.branchMatches;
    final nextBranch = target.branchMatches;
    _disposeOverlays(current);
    if (isMatchPrefix(currentBranch, nextBranch)) {
      final reused = reusePrefixMatches(currentBranch, nextBranch);
      if (reused.length > currentBranch.length &&
          reused.last.completer == null) {
        reused[reused.length - 1] = reused.last.copyWith(
          completer: Completer<Object?>(),
        );
      }
      return current.copyWith(
        matches: reused,
        uri: uri,
        shell: target.shell ?? current.shell,
        branchIndex: targetBranch,
        arguments: arguments,
        clearError: true,
      );
    }

    for (var i = 0; i < nextBranch.length - 1; i++) {
      nextBranch[i].dispose();
    }
    final leaf = _asImperative(nextBranch.last, arguments);
    return current.copyWith(
      matches: [...currentBranch, leaf],
      uri: uri,
      shell: target.shell ?? current.shell,
      branchIndex: targetBranch,
      arguments: arguments,
      clearError: true,
    );
  }

  /// 只换栈顶，再按 [pushNamed] 补齐。覆盖层优先于分支页。
  AdaptiveRouteMatchList pushReplacementNamed(
    AdaptiveRouteMatchList current,
    String routeName, {
    Object? result,
    Object? arguments,
  }) {
    final base = _removeTop(current, result);
    return pushNamed(base, routeName, arguments: arguments);
  }

  /// 先 [popUntil]，再 [pushNamed]。`predicate` 恒 false 即按 URL 重建。
  AdaptiveRouteMatchList pushNamedAndRemoveUntil(
    AdaptiveRouteMatchList current,
    String routeName,
    AdaptiveRoutePredicate predicate, {
    Object? arguments,
  }) {
    final trimmed = popUntil(current, predicate);
    return pushNamed(trimmed, routeName, arguments: arguments);
  }

  /// 先 pop 再 pushNamed。不能 pop 时只 pushNamed。
  AdaptiveRouteMatchList popAndPushNamed(
    AdaptiveRouteMatchList current,
    String routeName, {
    Object? result,
    Object? arguments,
  }) {
    final base = current.canPop ? pop(current, result) : current;
    return pushNamed(base, routeName, arguments: arguments);
  }

  /// 弹出栈顶（覆盖层或分支顶），根页不动。
  AdaptiveRouteMatchList pop(AdaptiveRouteMatchList current, [Object? result]) {
    return _removeTop(current, result);
  }

  /// 一直 pop 到 [predicate] 为 true 或不能再 pop。
  AdaptiveRouteMatchList popUntil(
    AdaptiveRouteMatchList current,
    AdaptiveRoutePredicate predicate,
  ) {
    var next = current;
    while (next.canPop && (next.last == null || !predicate(next.last!))) {
      next = pop(next);
    }
    return next;
  }

  /// 有覆盖层或分支深度 > 1。
  bool canPop(AdaptiveRouteMatchList current) => current.canPop;

  /// 切到另一分支：丢掉当前覆盖层。
  ///
  /// [restored] 非空时直接用那批 match（同一批实例），不再 [RouteRegistry.match]。
  AdaptiveRouteMatchList goBranch(
    AdaptiveRouteMatchList current, {
    required String location,
    List<AdaptiveRouteMatch>? restored,
    Object? arguments,
  }) {
    if (restored != null && restored.isNotEmpty) {
      _disposeOverlays(current);
      return AdaptiveRouteMatchList(
        matches: restored,
        uri: restored.last.uri,
        shell: current.shell,
        branchIndex: restored.last.branchIndex,
        arguments: restored.last.arguments,
      );
    }
    final target = registry.match(_parse(location), arguments: arguments);
    if (target.error != null) return target;
    _disposeOverlays(current);
    return target;
  }

  /// 目标是根 Navigator 覆盖层或壳外路由。
  bool _isOverlayTarget(AdaptiveRouteMatchList target) {
    if (target.matches.isEmpty) return true;
    if (target.matches.any((match) => match.route.onRootNavigator)) {
      return true;
    }
    return target.branchIndex == null;
  }

  /// 把目标叶子叠到已有栈上；空栈则用 URL 推导结果。
  AdaptiveRouteMatchList _pushOverlay(
    AdaptiveRouteMatchList current,
    AdaptiveRouteMatchList target,
    Uri uri,
    Object? arguments,
  ) {
    if (target.matches.isEmpty) return target;
    if (current.matches.isEmpty || current.error != null) {
      return target.copyWith(uri: uri, arguments: arguments);
    }
    for (var i = 0; i < target.matches.length - 1; i++) {
      target.matches[i].dispose();
    }
    final leaf = _asImperative(target.matches.last, arguments);
    return current.copyWith(
      matches: [...current.matches, leaf],
      uri: uri,
      arguments: arguments,
      clearError: true,
    );
  }

  /// 弹出覆盖层顶或分支顶。最后一页不可弹。
  AdaptiveRouteMatchList _removeTop(
    AdaptiveRouteMatchList current,
    Object? result,
  ) {
    if (!current.canPop) return current;
    final overlays = current.overlayMatches;
    if (overlays.isNotEmpty) {
      final removed = overlays.last;
      removed.dispose(result);
      final restOverlays = overlays.sublist(0, overlays.length - 1);
      final branch = current.branchMatches;
      final uri = restOverlays.isNotEmpty
          ? restOverlays.last.uri
          : (branch.isNotEmpty ? branch.last.uri : Uri.parse('/'));
      return current.copyWith(
        matches: [...branch, ...restOverlays],
        uri: uri,
        clearError: true,
      );
    }
    final branch = current.branchMatches;
    final removed = branch.last;
    removed.dispose(result);
    final rest = branch.sublist(0, branch.length - 1);
    return current.copyWith(
      matches: rest,
      uri: rest.last.uri,
      clearError: true,
    );
  }

  /// 丢掉覆盖层（切分支 / 栏内导航时）。
  static void _disposeOverlays(AdaptiveRouteMatchList current) {
    for (final overlay in current.overlayMatches) {
      overlay.dispose();
    }
  }

  /// 命令式页：新 key + Completer，避免与 URL 推导页撞 key。
  AdaptiveRouteMatch _asImperative(
    AdaptiveRouteMatch match,
    Object? arguments,
  ) {
    _imperativeId += 1;
    return match.copyWith(
      pageKey: ValueKey<String>('imp:$_imperativeId:${match.matchedLocation}'),
      completer: Completer<Object?>(),
      isImperative: true,
      arguments: arguments,
      queryParameters: match.queryParameters,
    );
  }

  static Uri _parse(String routeName) {
    if (!routeName.startsWith('/')) {
      return Uri.parse('/$routeName');
    }
    return Uri.parse(routeName);
  }
}
