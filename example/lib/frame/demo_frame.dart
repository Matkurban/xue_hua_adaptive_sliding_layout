import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router.dart';

/// 网页顶部的宽度预设，让桌面访客不用缩放窗口就能看 Phone / Tablet / Desktop。
enum DemoSizePreset {
  phone(412, 'Phone'),
  foldable(700, 'Foldable'),
  tablet(1024, 'Tablet'),
  desktop(null, 'Desktop');

  const DemoSizePreset(this.width, this.label);

  /// null 表示占满窗口。
  final double? width;
  final String label;
}

/// 当前选中的宽度预设。
final Signal<DemoSizePreset> demoSizePreset = signal(DemoSizePreset.desktop);

/// 包在 [MaterialApp.builder] 里：约束内容宽度并显示 URL / 模式。
class DemoFrame extends StatelessWidget {
  /// [child] 为 Router 产出的子树。
  const DemoFrame({super.key, required this.child});

  /// [MaterialApp.builder] 传入的路由内容。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final preset = demoSizePreset.value;
        final loc = appRouter.location.value;
        final width = MediaQuery.sizeOf(context).width;
        final framed = preset.width ?? width;
        final bp = const LayoutBreakpoints();
        final mode = bp.isCompact(framed)
            ? 'compact'
            : bp.isMedium(framed)
            ? 'medium'
            : 'expanded';
        final columns = bp.visibleColumnCount(framed);
        return Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Demo', style: Theme.of(context).textTheme.titleSmall),
                    for (final item in DemoSizePreset.values)
                      ChoiceChip(
                        label: Text(item.label),
                        selected: item == preset,
                        onSelected: (_) => demoSizePreset.value = item,
                      ),
                    Text('$loc  ·  $mode  ·  $columns col'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: framed,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: Size(framed, MediaQuery.sizeOf(context).height),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
