import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/transitions/adaptive_page_transition_type.dart';

import 'adaptive_route_base.dart';
import 'adaptive_route_state.dart';

/// 页面工厂。第二参数是当前匹配快照。
typedef AdaptiveRouteBuilder = Widget Function(
  BuildContext context,
  AdaptiveRouteState state,
);

/// 入栏时的面包屑 / 栏标题。匹配时求值一次，没有 [BuildContext]。
///
/// 国际化用 gen-l10n 的 `lookupAppLocalizations(locale)` 或 `Intl.defaultLocale`；
/// 需要 context 或要跟随语言切换的，在页面里写 `AdaptivePaneScope.title`。
typedef AdaptiveTitleBuilder = String Function(AdaptiveRouteState state);

/// 返回非 null 的 location 则改去那里。可同步或异步。
typedef AdaptiveRedirect = FutureOr<String?> Function(
  BuildContext context,
  AdaptiveRouteState state,
);

/// 返回 false 则取消这次离开（`AdaptiveRouter.maybePop` / 系统返回 / 浏览器后退）。
typedef AdaptiveOnExit = FutureOr<bool> Function(
  BuildContext context,
  AdaptiveRouteState state,
);

/// 自定义过场，签名与 [PageRouteBuilder.transitionsBuilder] 相同。
typedef AdaptiveTransitionsBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
);

/// 一张页面路由。子 [routes] 的 path 为相对路径，`:param` 表示一个路径段。
///
/// [builder] 与 [redirect] 至少提供一个。顺序优先：列表里先写的先匹配。
class AdaptiveRoute extends AdaptiveRouteBase {
  /// [path] 为 `/mail` 或相对 `:id`；[name] 供 `AdaptiveRouter.namedLocation` 使用。
  AdaptiveRoute({
    required this.path,
    this.name,
    this.builder,
    this.title,
    this.fullscreen = false,
    this.fullscreenDialog = false,
    this.hidesBottomBarWhenPushed = true,
    this.opaque = true,
    this.barrierColor,
    this.barrierDismissible = false,
    this.transitionType,
    this.transitionsBuilder,
    this.transitionDuration,
    this.reverseTransitionDuration,
    this.transitionCurve,
    this.reverseTransitionCurve,
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

  /// 可选稳定名，给 `AdaptiveRouter.namedLocation` 用。全局不可重复。
  final String? name;

  /// 构建本页 Widget。redirect-only 路由可为 null。
  final AdaptiveRouteBuilder? builder;

  /// 入栈时的栏标题；缺省由 path / name humanize。
  ///
  /// 匹配时求值一次，无 context；state 的 `fullPath` 为完整模式、`uri` 带 query。
  final AdaptiveTitleBuilder? title;

  /// 为 true 时在任何宽度都叠在根 Navigator 上，不进入滑动栏（登录、照片）。
  final bool fullscreen;

  /// Material 全屏对话框（`MaterialPage.fullscreenDialog`：上滑、关闭图标）。
  ///
  /// 语义是“模态对话框”，为 true 时同样在任何宽度叠在根 Navigator 上
  /// （见 [onRootNavigator]）。只想在手机上隐藏底栏用 [hidesBottomBarWhenPushed]。
  final bool fullscreenDialog;

  /// 是否叠在根 Navigator 上：[fullscreen] 或 [fullscreenDialog]。
  bool get onRootNavigator => fullscreen || fullscreenDialog;

  /// compact（低于 `LayoutBreakpoints.compactMaxWidth`，宿主通常画 bottom bar）
  /// 下推入本页时，把本页推到宿主 chrome 之上，底栏被盖住。默认 true。
  ///
  /// 与 iOS `UIViewController.hidesBottomBarWhenPushed` 同名同义。
  /// 设 false 则本页留在 chrome 内的分支 Navigator 里，底栏保留。
  /// medium 的 rail 与 expanded 双栏不受影响；分支根页与 [onRootNavigator]
  /// 的页忽略本值。
  final bool hidesBottomBarWhenPushed;

  /// 传给页面路由的 `opaque`。默认不透明。
  final bool opaque;

  /// 自定义过场时的屏障色；透明覆盖层常用半透明黑。
  final Color? barrierColor;

  /// 自定义过场时点击屏障是否弹出。
  final bool barrierDismissible;

  /// 预置页面过渡动画类型（如 `fade`、`slideRightToLeft`、`cupertino`、`sharedAxisHorizontal` 等）。
  /// 若同时提供了 [transitionsBuilder]，以 [transitionsBuilder] 为准。
  final AdaptivePageTransitionType? transitionType;

  /// 自定义页面过场构建器（优先级高于 [transitionType]）。
  final AdaptiveTransitionsBuilder? transitionsBuilder;

  /// 入场过场动画时长。未指定时使用 [transitionType] 的推荐时长或 300ms。
  final Duration? transitionDuration;

  /// 退场（pop）过场动画时长。未指定时回落到 [transitionDuration]。
  final Duration? reverseTransitionDuration;

  /// 预置 [transitionType] 使用的正向动画曲线。
  final Curve? transitionCurve;

  /// 预置 [transitionType] 使用的反向动画曲线。
  final Curve? reverseTransitionCurve;

  /// 匹配到本路由后、入栈前的 redirect。
  final AdaptiveRedirect? redirect;

  /// `AdaptiveRouter.maybePop` 等询问式离开时调用。
  final AdaptiveOnExit? onExit;

  /// 相对路径子路由，顺序优先匹配。
  final List<AdaptiveRoute> routes;

  /// 解析当前路由最终生效的 [AdaptivePageTransitionType]。
  AdaptivePageTransitionType effectiveTransitionType({
    AdaptivePageTransitionType? shellTransitionType,
    AdaptivePageTransitionType? routerTransitionType,
  }) {
    return transitionType ??
        shellTransitionType ??
        routerTransitionType ??
        AdaptivePageTransitionType.platform;
  }

  /// 解析当前路由最终生效的 [AdaptiveTransitionsBuilder]；
  /// 若走默认平台 Material 路由则返回 null。
  AdaptiveTransitionsBuilder? effectiveTransitionsBuilder({
    AdaptivePageTransitionType? shellTransitionType,
    AdaptiveTransitionsBuilder? shellTransitionsBuilder,
    Curve? shellTransitionCurve,
    Curve? shellReverseTransitionCurve,
    AdaptivePageTransitionType? routerTransitionType,
    AdaptiveTransitionsBuilder? routerTransitionsBuilder,
    Curve? routerTransitionCurve,
    Curve? routerReverseTransitionCurve,
  }) {
    if (transitionsBuilder != null) return transitionsBuilder;
    final curve =
        transitionCurve ?? shellTransitionCurve ?? routerTransitionCurve;
    final reverseCurve =
        reverseTransitionCurve ??
        shellReverseTransitionCurve ??
        routerReverseTransitionCurve;
    if (transitionType != null) {
      return transitionType!.builder(curve: curve, reverseCurve: reverseCurve);
    }
    if (shellTransitionsBuilder != null) return shellTransitionsBuilder;
    if (shellTransitionType != null) {
      return shellTransitionType.builder(
        curve: curve,
        reverseCurve: reverseCurve,
      );
    }
    if (routerTransitionsBuilder != null) return routerTransitionsBuilder;
    if (routerTransitionType != null) {
      return routerTransitionType.builder(
        curve: curve,
        reverseCurve: reverseCurve,
      );
    }
    return null;
  }

  /// 解析当前路由最终生效的入场动画时长。
  Duration effectiveTransitionDuration({
    Duration? shellTransitionDuration,
    AdaptivePageTransitionType? shellTransitionType,
    Duration? routerTransitionDuration,
    AdaptivePageTransitionType? routerTransitionType,
  }) {
    if (transitionDuration != null) return transitionDuration!;
    if (transitionType != null) return transitionType!.defaultDuration;
    if (shellTransitionDuration != null) return shellTransitionDuration;
    if (shellTransitionType != null) return shellTransitionType.defaultDuration;
    if (routerTransitionDuration != null) return routerTransitionDuration;
    if (routerTransitionType != null) {
      return routerTransitionType.defaultDuration;
    }
    return const Duration(milliseconds: 300);
  }

  /// 解析当前路由最终生效的退场动画时长。
  Duration effectiveReverseTransitionDuration({
    Duration? shellReverseTransitionDuration,
    Duration? shellTransitionDuration,
    AdaptivePageTransitionType? shellTransitionType,
    Duration? routerReverseTransitionDuration,
    Duration? routerTransitionDuration,
    AdaptivePageTransitionType? routerTransitionType,
  }) {
    if (reverseTransitionDuration != null) return reverseTransitionDuration!;
    if (transitionDuration != null) return transitionDuration!;
    if (transitionType != null) return transitionType!.defaultDuration;
    if (shellReverseTransitionDuration != null) {
      return shellReverseTransitionDuration;
    }
    if (shellTransitionDuration != null) return shellTransitionDuration;
    if (shellTransitionType != null) return shellTransitionType.defaultDuration;
    if (routerReverseTransitionDuration != null) {
      return routerReverseTransitionDuration;
    }
    return effectiveTransitionDuration(
      shellTransitionDuration: shellTransitionDuration,
      shellTransitionType: shellTransitionType,
      routerTransitionDuration: routerTransitionDuration,
      routerTransitionType: routerTransitionType,
    );
  }
}
