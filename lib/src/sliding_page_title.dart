import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/sliding_window_page.dart';

/// 滑动栏页面标题：入栈初值、AppBar 同步、动态 [report]。
class SlidingPageTitle extends InheritedWidget {
  /// [page] 为当前栏对应的栈页，其 [SlidingWindowPage.title] 驱动面包屑。
  const SlidingPageTitle({super.key, required this.page, required super.child});

  /// 本栏绑定的栈页。
  final SlidingWindowPage page;

  /// 位于栏内时返回，否则 null（窄屏 fallback 页没有此 scope）。
  static SlidingPageTitle? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SlidingPageTitle>();
  }

  /// 把面包屑标题改成 [title]。空串或与当前值相同则忽略；写入排到下一帧，
  /// 以便首帧仍可从 [AppBar.title] 同步。
  void report(String title) {
    if (title.isEmpty || page.title.peek() == title) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (page.title.peek() == title) return;
      page.title.value = title;
    });
  }

  /// 将路由 path 或 widget 类型名转为可读标题（无业务 l10n）。
  ///
  /// 去掉 `/`、`:params`、末尾 `Page`/`View`，再在驼峰处插空格。
  static String humanize(String name) {
    if (name.startsWith('/')) {
      final parts = name
          .split('/')
          .where((part) => part.isNotEmpty && !part.startsWith(':'))
          .toList();
      if (parts.isNotEmpty) return _humanize(parts.last);
    }
    final stripped = name.replaceAll(RegExp(r'(Page|View)$'), '');
    if (stripped.isNotEmpty && stripped != name) return _humanize(stripped);
    return name;
  }

  /// 在驼峰边界插入空格并大写首字母。
  static String _humanize(String raw) {
    final spaced = raw.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match[1]} ${match[2]}',
    );
    if (spaced.isEmpty) return raw;
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  /// [page] 实例变化时通知依赖。
  @override
  bool updateShouldNotify(SlidingPageTitle oldWidget) => page != oldWidget.page;
}
