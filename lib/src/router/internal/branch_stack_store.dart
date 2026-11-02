import 'package:flutter/foundation.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match_list.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/internal/route_redirect_resolver.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/route_registry.dart';

/// 管理多分支栈快照、分支位置记录以及按 location 记忆的 `arguments`。
class BranchStackStore {
  BranchStackStore(this.registry);

  final RouteRegistry registry;

  final Map<int, List<AdaptiveRouteMatch>> branchStacks =
      <int, List<AdaptiveRouteMatch>>{};

  final Map<int, String> branchLocations = <int, String>{};

  /// 栈上每页（按 matchedLocation）最近一次携带的 arguments。
  ///
  /// 页面的 arguments 永远跟着它自己的 match 走；但按 URL 重新推导出来的 match（系统 /
  /// 浏览器 URL、`refresh` 重定向、未保存栈的分支切换、未访问分支的初始栈）没有参数，
  /// 这里用同一位置上次的参数补回，避免重建时拿到 null。只保留仍在某个栈里的位置。
  final Map<String, Object> argumentsByLocation = <String, Object>{};

  bool get hasSavedBranches => branchStacks.isNotEmpty;

  /// [index] 分支是否打开过（当前分支，或离开时存过栈）。没打开过的分支不建页面。
  bool hasVisitedBranch(int index, AdaptiveRouteMatchList current) {
    if (current.branchIndex == index) return true;
    final stored = branchStacks[index];
    return stored != null && stored.isNotEmpty;
  }

  /// 当前分支应展示的栈；非当前分支用上次快照或 initialLocation。
  List<AdaptiveRouteMatch> stackForBranch(
    int index,
    AdaptiveRouteMatchList current,
  ) {
    if (current.branchIndex == index) return current.branchMatches;
    final stored = branchStacks[index];
    if (stored != null && stored.isNotEmpty) return stored;
    final shellRoute = registry.shell;
    if (shellRoute == null || index >= shellRoute.branches.length) {
      return const <AdaptiveRouteMatch>[];
    }
    return restoreArguments(
      registry
          .match(Uri.parse(shellRoute.branches[index].initialLocation))
          .branchMatches,
      current,
    );
  }

  /// 给新推导出的缺少 arguments 的 match 补回同一位置记住的参数；
  /// 已在栈上且原本无参的 match 保持 null，不补参数。
  List<AdaptiveRouteMatch> restoreArguments(
    List<AdaptiveRouteMatch> matches,
    AdaptiveRouteMatchList current,
  ) {
    final liveNullMatches = <AdaptiveRouteMatch>{
      for (final m in current.matches)
        if (m.arguments == null) m,
      for (final stack in branchStacks.values)
        for (final m in stack)
          if (m.arguments == null) m,
    };
    bool shouldRestore(AdaptiveRouteMatch m) {
      return m.arguments == null &&
          !liveNullMatches.contains(m) &&
          argumentsByLocation.containsKey(m.matchedLocation);
    }

    if (!matches.any(shouldRestore)) {
      return matches;
    }
    return [
      for (final m in matches)
        if (shouldRestore(m))
          m.copyWith(arguments: argumentsByLocation[m.matchedLocation])
        else
          m,
    ];
  }

  /// 记住当前所有栈里每页非空的 arguments，并清掉已无非空参数的栈位置。
  void rememberArguments(AdaptiveRouteMatchList current) {
    argumentsByLocation.clear();
    void visit(Iterable<AdaptiveRouteMatch> matches) {
      for (final m in matches) {
        final args = m.arguments;
        if (args != null) argumentsByLocation[m.matchedLocation] = args;
      }
    }

    for (final stack in branchStacks.values) {
      visit(stack);
    }
    visit(current.matches);
  }

  /// 在栈切换时保存旧分支与新分支快照，并销毁不再被任何栈持有的 match。
  Set<Key> syncStacksOnTransition(
    AdaptiveRouteMatchList old,
    AdaptiveRouteMatchList next,
  ) {
    if (old.branchIndex != null &&
        old.branchIndex != next.branchIndex &&
        old.branchMatches.isNotEmpty) {
      branchStacks[old.branchIndex!] = old.branchMatches;
      branchLocations[old.branchIndex!] = _branchLoc(old);
    }
    if (next.branchIndex != null) {
      branchStacks[next.branchIndex!] = next.branchMatches;
      branchLocations[next.branchIndex!] = _branchLoc(next);
    }
    final kept = <Key>{
      for (final match in next.matches) match.pageKey,
      for (final stack in branchStacks.values)
        for (final match in stack) match.pageKey,
    };
    for (final match in old.matches) {
      if (!kept.contains(match.pageKey)) {
        match.dispose();
      }
    }
    return kept;
  }

  void disposeUnkeptMatches(
    Iterable<AdaptiveRouteMatch> candidates,
    AdaptiveRouteMatchList current,
  ) {
    final kept = <AdaptiveRouteMatch>{
      ...current.matches,
      for (final stack in branchStacks.values) ...stack,
    };
    for (final match in candidates) {
      if (!kept.contains(match)) {
        match.dispose();
      }
    }
  }

  void disposeAll(AdaptiveRouteMatchList current) {
    final allMatches = <AdaptiveRouteMatch>{
      ...current.matches,
      for (final stack in branchStacks.values) ...stack,
    };
    for (final match in allMatches) {
      match.dispose();
    }
    branchStacks.clear();
    branchLocations.clear();
    argumentsByLocation.clear();
  }

  static String _branchLoc(AdaptiveRouteMatchList list) {
    final branch = list.branchMatches;
    if (branch.isEmpty) return RouteRedirectResolver.formatLocation(list.uri);
    return RouteRedirectResolver.formatLocation(branch.last.uri);
  }
}
