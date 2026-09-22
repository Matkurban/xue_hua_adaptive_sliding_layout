import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

/// compact 用 [NavigationBar]，其余用 [NavigationRail]。
///
/// 点当前 Tab 会 `goBranch(i, initialLocation: true)` 回到该分支根。
/// 栈底系统返回由 [PopScope] 拦住并弹出退出确认。
class AppShell extends StatelessWidget {
  /// [shell] 来自 [AdaptiveShellRoute.builder]；[child] 必须放进内容区。
  const AppShell({super.key, required this.shell, required this.child});

  /// 当前壳层快照。
  final AdaptiveShellState shell;

  /// 当前分支的栏位 / Navigator。
  final Widget child;

  static const _destinations = <({IconData icon, String label})>[
    (icon: Icons.home_outlined, label: '首页'),
    (icon: Icons.shopping_cart_outlined, label: '购物车'),
    (icon: Icons.contacts_outlined, label: '联系人'),
    (icon: Icons.person_outlined, label: '我的'),
  ];

  void _select(int index) {
    if (index == shell.currentIndex) {
      shell.goBranch(index, initialLocation: true);
      return;
    }
    shell.goBranch(index);
  }

  /// 系统返回到主页栈底时弹出确认；确认后 [SystemNavigator.pop]（iOS 上被系统忽略）。
  ///
  /// 对话框挂在壳层 Navigator（`useRootNavigator: false`），Stay 后该层
  /// `didPopNext` 会重新声明能处理返回。再 dispatch 一次是给预测性返回保险：
  /// 根 Navigator 上的弹框关掉后 Android 否则会 `setFrameworkHandlesBack(false)`。
  Future<void> _confirmExit(BuildContext context) async {
    final quit = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return AlertDialog(
          key: const Key('exit-dialog'),
          title: const Text('Exit app?'),
          actions: [
            TextButton(
              key: const Key('exit-stay'),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            TextButton(
              key: const Key('exit-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
    if (quit == true) {
      SystemNavigator.pop();
    } else if (context.mounted) {
      const NavigationNotification(canHandlePop: true).dispatch(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: shell.isCompact ? _compact() : _rail(),
    );
  }

  Widget _compact() {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _select,
        destinations: [
          for (final item in _destinations)
            NavigationDestination(icon: Icon(item.icon), label: item.label),
        ],
      ),
    );
  }

  Widget _rail() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _select,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final item in _destinations)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
