import 'package:flutter/widgets.dart';

import 'adaptive_router.dart';

/// 向子树暴露 [AdaptiveRouter]。
class AdaptiveRouterScope extends InheritedWidget {
  /// [router] 为本应用唯一的路由器实例。
  const AdaptiveRouterScope({
    super.key,
    required this.router,
    required super.child,
  });

  /// 当前路由器。
  final AdaptiveRouter router;

  @override
  bool updateShouldNotify(AdaptiveRouterScope oldWidget) =>
      router != oldWidget.router;
}
