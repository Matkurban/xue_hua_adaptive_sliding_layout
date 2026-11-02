import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_router.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/pages/adaptive_page.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/routes/exit_guard_route_mixin.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/routes/keep_underlying_ticker_route.dart';

/// 自定义过场的页路由。
class AdaptiveTransitionRoute<T> extends PageRouteBuilder<T>
    with ExitGuardRouteMixin<T>, KeepUnderlyingTickerRoute<T> {
  AdaptiveTransitionRoute({
    required AdaptivePage<T> page,
    AdaptiveTransitionsBuilder? transitionsBuilder,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
  }) : super(
         settings: page,
         fullscreenDialog: page.match.route.fullscreenDialog,
         opaque: page.match.route.opaque,
         barrierColor: page.match.route.barrierColor,
         barrierDismissible: page.match.route.barrierDismissible,
         transitionDuration:
             transitionDuration ??
             page.match.route.transitionDuration ??
             const Duration(milliseconds: 300),
         reverseTransitionDuration:
             reverseTransitionDuration ??
             page.match.route.reverseTransitionDuration ??
             transitionDuration ??
             page.match.route.transitionDuration ??
             const Duration(milliseconds: 300),
         pageBuilder: (context, animation, secondaryAnimation) => page.child,
         transitionsBuilder:
             transitionsBuilder ?? page.match.route.transitionsBuilder!,
       );

  AdaptivePage<T> get _page => settings as AdaptivePage<T>;

  @override
  AdaptiveRouter get router => _page.router;

  @override
  AdaptiveRouteMatch get match => _page.match;

  @override
  bool get opaque => match.route.opaque;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    if (nextRoute is PageRoute && nextRoute.opaque) {
      return true;
    }
    return super.canTransitionTo(nextRoute);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => wrapOffstageContent(_page.child);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final transitioned = super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );
    if (!opaque) return transitioned;
    // 当作为下层不透明路由正在执行 secondaryAnimation（如三级路由推入时的视差/共享轴/穿透渐变），
    // 为本路由补一层不透明 surface 底衬，防止更底层的根页面在退场缩小时透出。
    return AnimatedBuilder(
      animation: secondaryAnimation,
      builder: (context, builtChild) {
        if (secondaryAnimation.isDismissed) return builtChild!;
        return ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: builtChild,
        );
      },
      child: transitioned,
    );
  }
}
