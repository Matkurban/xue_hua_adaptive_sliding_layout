import 'package:material_ui/material_ui.dart';

/// 双栏视口中单栏的默认卡片装饰容器。
class PaneCardShell extends StatelessWidget {
  const PaneCardShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        elevation: 2,
        color: colorScheme.surface,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
