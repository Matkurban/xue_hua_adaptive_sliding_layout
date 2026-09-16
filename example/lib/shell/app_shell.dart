import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

/// compact 用 [NavigationBar]，其余用 [NavigationRail]。
///
/// 点当前 Tab 会 `goBranch(i, initialLocation: true)` 回到该分支根。
class AppShell extends StatelessWidget {
  /// [shell] 来自 [AdaptiveShellRoute.builder]；[child] 必须放进内容区。
  const AppShell({super.key, required this.shell, required this.child});

  /// 当前壳层快照。
  final AdaptiveShellState shell;

  /// 当前分支的栏位 / Navigator。
  final Widget child;

  static const _destinations = <({IconData icon, String label})>[
    (icon: Icons.mail_outlined, label: 'Mail'),
    (icon: Icons.people_outlined, label: 'Contacts'),
    (icon: Icons.settings_outlined, label: 'Settings'),
    (icon: Icons.science_outlined, label: 'Playground'),
  ];

  void _select(int index) {
    if (index == shell.currentIndex) {
      shell.goBranch(index, initialLocation: true);
      return;
    }
    shell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    if (shell.isCompact) {
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
