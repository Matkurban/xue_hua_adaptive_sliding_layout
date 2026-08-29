import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 滑动窗口导航栈中的一页。
class SlidingWindowPage {
  /// [key] 用于视口保活；[name] 为路由 id；[builder] 构建栏内内容。
  /// [title] 缺省等于 [name]。[completer] 在弹出或替换时完成。
  SlidingWindowPage({
    required this.key,
    required this.name,
    required this.builder,
    String? title,
    Completer<Object?>? completer,
  }) : title = signal(title ?? name),
       completer = completer ?? Completer<Object?>();

  /// 用于视口保活与 [PageStorageKey]。根页由 controller 写成 `sliding-root`。
  final LocalKey key;

  /// 路由 id（path 或 widget 类型名）；空字符串则面包屑可跳过该项。
  final String name;

  /// 面包屑展示标题，可随 AppBar / 会话名更新。
  final Signal<String> title;

  /// 在栏内 [Navigator] 里构建本页子树。
  final WidgetBuilder builder;

  /// [SlidingWindowController.pop] / 替换时 complete，供 `push` 的 Future 收结果。
  final Completer<Object?> completer;

  /// 销毁 [title] signal。由 controller 在移出栈时调用。
  void dispose() {
    title.dispose();
  }
}
