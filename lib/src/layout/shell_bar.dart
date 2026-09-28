import 'package:material_ui/material_ui.dart';

/// compact 壳层：把底栏放进分支页面路由内部。
///
/// 底栏是页面的子组件，不是独立的 [OverlayEntry]。
/// `showModalBottomSheet(useRootNavigator: false)` 压上的弹层在该页之上，
/// 遮罩和 sheet 盖住整页，包括底栏。
/// 不要再把同一块栏放进 [Scaffold.bottomNavigationBar]：
/// Scaffold 会把它画在 body 的 Navigator 外面，弹层盖不住。
///
/// 用在 [AdaptiveShellRoute.builder] 的 compact 分支，[child] 是壳层交给宿主的内容。
/// 宽屏 rail 不要用本组件。
class AdaptiveShellChrome extends StatelessWidget {
  /// [child] 为壳层内容；[bottomNavigationBar] 每次画栏时调用，返回一个新的底栏。
  const AdaptiveShellChrome({
    super.key,
    required this.child,
    required this.bottomNavigationBar,
  });

  /// 壳 builder 收到的内容区，一般就是分支 Navigator。
  final Widget child;

  /// 底栏工厂。每个仍和底栏同一层的页面各建一份，不能共用同一个 [Widget] 实例。
  final WidgetBuilder bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return _ShellBarData(
      bottomNavigationBar: bottomNavigationBar,
      child: child,
    );
  }
}

/// 向分支页面提供底栏工厂。
class _ShellBarData extends InheritedWidget {
  /// [bottomNavigationBar] 为底栏工厂；[child] 为壳层内容。
  const _ShellBarData({
    required this.bottomNavigationBar,
    required super.child,
  });

  /// 每次需要底栏时调用，返回新的底栏 widget。
  final WidgetBuilder bottomNavigationBar;

  /// 只读取，不订阅。没有 [AdaptiveShellChrome] 时返回 null。
  static _ShellBarData? read(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_ShellBarData>();
  }

  @override
  bool updateShouldNotify(_ShellBarData oldWidget) {
    return bottomNavigationBar != oldWidget.bottomNavigationBar;
  }
}

/// 有 [AdaptiveShellChrome] 时返回页面包裹；否则 null。
///
/// 只包分支 Navigator 里的页面，不包弹层。[context] 取壳层分支的 context。
Widget Function(Widget child)? adaptiveShellBarFrame(BuildContext context) {
  final data = _ShellBarData.read(context);
  if (data == null) return null;
  return (Widget child) {
    return _ShellBarPage(
      bottomNavigationBar: data.bottomNavigationBar,
      child: child,
    );
  };
}

/// 页面在上、底栏在下。弹层是这条页面路由之上的 Route，会盖住底栏。
class _ShellBarPage extends StatelessWidget {
  /// [bottomNavigationBar] 画底栏；[child] 是页面子树。
  const _ShellBarPage({required this.bottomNavigationBar, required this.child});

  /// 底栏工厂。
  final WidgetBuilder bottomNavigationBar;

  /// 页面内容。底部安全区交给底栏，避免和页面里的 [SafeArea] 叠两层。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: child,
          ),
        ),
        bottomNavigationBar(context),
      ],
    );
  }
}
