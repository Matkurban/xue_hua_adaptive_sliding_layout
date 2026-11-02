import 'package:material_ui/material_ui.dart';

/// 双栏视口深度不足时的默认右侧空态占位组件。
class SlidingPlaceholder extends StatelessWidget {
  const SlidingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerLow,
      child: Center(
        child: Icon(
          Icons.web_asset_outlined,
          size: 48,
          color: colorScheme.outline,
        ),
      ),
    );
  }
}
