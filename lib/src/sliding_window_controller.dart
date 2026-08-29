import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_window_page.dart';

/// 单个功能模块（通常是一个 Tab）的滑动窗口导航栈。根页不可弹出。
///
/// 日常跳转应走 [AdaptiveNavigator]；本类的 [push] / [openAfter] / [replace]
/// 是栈算法实现细节。
class SlidingWindowController {
  /// 空栈。根页由 [ensureRoot] 或宿主壳首次 build 写入。
  SlidingWindowController();

  /// 当前栈快照。视口与面包屑订阅此 signal。
  final Signal<List<SlidingWindowPage>> pages = signal(const <SlidingWindowPage>[]);

  /// 除根以外还有页时为 true。
  bool get canPop => pages.value.length > 1;

  /// 栈内页数（含根）。可大于视口可见栏数。
  int get depth => pages.value.length;

  /// 从后往前找同名页下标；未找到返回 -1。空名不匹配。
  int indexOfName(String name) {
    if (name.isEmpty) return -1;
    final all = pages.value;
    for (var i = all.length - 1; i >= 0; i--) {
      if (all[i].name == name) return i;
    }
    return -1;
  }

  /// 视口应展示的栈顶最后 [visibleCount] 页。
  List<SlidingWindowPage> visiblePages(int visibleCount) {
    final all = pages.value;
    if (all.isEmpty) return const [];
    final count = visibleCount < 1 ? 1 : visibleCount;
    final start = all.length > count ? all.length - count : 0;
    return all.sublist(start);
  }

  /// 若栈为空则压入根页，已有内容时忽略。
  ///
  /// 根页 [SlidingWindowPage.key] 固定为 `ValueKey('sliding-root')`，
  /// [AdaptiveNavigator.untilRoot] 依赖此 key。
  void ensureRoot({required String name, required WidgetBuilder builder, String? title}) {
    if (pages.value.isNotEmpty) return;
    pages.value = [
      SlidingWindowPage(
        key: const ValueKey<String>('sliding-root'),
        name: name,
        title: title ?? name,
        builder: builder,
      ),
    ];
  }

  /// 嵌套压栈（Push Slide）。深度加 1，双栏视口在深度 ≥ 3 时向左平移。
  Future<T?> push<T extends Object?>(
    WidgetBuilder builder, {
    String name = '',
    String? title,
    LocalKey? key,
  }) {
    final page = SlidingWindowPage(
      key: key ?? UniqueKey(),
      name: name,
      title: title ?? name,
      builder: builder,
    );
    pages.value = [...pages.value, page];
    return page.completer.future.then((value) => value as T?);
  }

  /// 弹出栈顶并完成其 [SlidingWindowPage.completer]。根页不可弹，返回 false。
  bool pop<T extends Object?>([T? result]) {
    if (!canPop) return false;
    final list = [...pages.value];
    final page = list.removeLast();
    pages.value = list;
    if (!page.completer.isCompleted) {
      page.completer.complete(result);
    }
    page.dispose();
    return true;
  }

  /// 弹出到根页。根页本身不可弹出。
  void popToRoot() {
    while (canPop) {
      pop();
    }
  }

  /// 栈顶不满足 [predicate] 就继续 [pop]，直到根或谓词为 true。
  void popUntil(bool Function(SlidingWindowPage page) predicate) {
    while (canPop && !predicate(pages.value.last)) {
      pop();
    }
  }

  /// 保留前 [keepCount] 页，丢掉后面的页，再压入新页。
  ///
  /// [keepCount] ≥ 当前深度时等同于 [push]。栈空时等同于 [push]。
  /// [keepCount] 小于 1 时按 1 处理，避免丢掉根。
  Future<T?> openAfter<T extends Object?>(
    int keepCount,
    WidgetBuilder builder, {
    String name = '',
    String? title,
    LocalKey? key,
  }) {
    final all = pages.value;
    if (all.isEmpty) {
      return push<T>(builder, name: name, title: title, key: key);
    }
    final keep = keepCount < 1 ? 1 : (keepCount > all.length ? all.length : keepCount);
    if (keep >= all.length) {
      return push<T>(builder, name: name, title: title, key: key);
    }
    final retained = all.sublist(0, keep);
    for (final page in all.skip(keep)) {
      if (!page.completer.isCompleted) {
        page.completer.complete(null);
      }
      page.dispose();
    }
    final next = SlidingWindowPage(
      key: key ?? UniqueKey(),
      name: name,
      title: title ?? name,
      builder: builder,
    );
    pages.value = [...retained, next];
    return next.completer.future.then((value) => value as T?);
  }

  /// 同级 Replace：保留根页，第二栏换成新页。
  ///
  /// 栈形始终为 `[根, 二级]`。深度 1 时效果等同于 push 到深度 2；
  /// 深度 ≥ 2 时丢掉根以上全部旧页，**不会**把旧二级推进左栏（因此双栏视口不横向滑动）。
  /// 嵌套子页请用 [push]（Push Slide）。
  Future<T?> openSecondary<T extends Object?>(
    WidgetBuilder builder, {
    String name = '',
    String? title,
    LocalKey? key,
  }) {
    return openAfter<T>(1, builder, name: name, title: title, key: key);
  }

  /// 替换栈顶（含根页）。只换最上一页，不会清掉中间层。
  Future<T?> replace<T extends Object?>(
    WidgetBuilder builder, {
    String name = '',
    String? title,
    LocalKey? key,
  }) {
    final list = [...pages.value];
    if (list.isNotEmpty) {
      final removed = list.removeLast();
      if (!removed.completer.isCompleted) {
        removed.completer.complete(null);
      }
      removed.dispose();
    }
    final page = SlidingWindowPage(
      key: key ?? UniqueKey(),
      name: name,
      title: title ?? name,
      builder: builder,
    );
    list.add(page);
    pages.value = list;
    return page.completer.future.then((value) => value as T?);
  }

  /// 完成残留 Future、销毁各页 title、清空并销毁 [pages] signal。
  void dispose() {
    for (final page in pages.value) {
      if (!page.completer.isCompleted) {
        page.completer.complete(null);
      }
      page.dispose();
    }
    pages.value = const [];
    pages.dispose();
  }
}
