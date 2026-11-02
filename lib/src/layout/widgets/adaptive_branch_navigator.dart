import 'package:material_ui/material_ui.dart';

/// 分支 1 栏 Navigator：compact 下命令式压入的弹层（如 `showModalBottomSheet`、
/// `showDialog` 且 `useRootNavigator: false`）自动挂到外层 [chromeNavigatorKey]，
/// 从而盖住宿主 [Scaffold.bottomNavigationBar]。
class AdaptiveBranchNavigator extends Navigator {
  const AdaptiveBranchNavigator({
    super.key,
    this.chromeNavigatorKey,
    required super.pages,
    super.onDidRemovePage,
    required super.transitionDelegate,
  });

  final GlobalKey<NavigatorState>? chromeNavigatorKey;

  @override
  NavigatorState createState() => _AdaptiveBranchNavigatorState();
}

class _AdaptiveBranchNavigatorState extends NavigatorState {
  NavigatorState? get _chromeNavigator {
    final w = widget;
    if (w is! AdaptiveBranchNavigator) return null;
    final state = w.chromeNavigatorKey?.currentState;
    return state != null && state.mounted ? state : null;
  }

  @override
  Future<T?> push<T extends Object?>(Route<T> route) {
    final chrome = _chromeNavigator;
    if (chrome != null && route.settings is! Page) {
      return chrome.push<T>(route);
    }
    return super.push<T>(route);
  }
}
