import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/transitions/transition_preset_meta.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_names.dart';

/// 页面过渡效果实时预览页：展示当前过渡效果信息，并支持继续推入下一层以测试 `secondaryAnimation`。
class TransitionDetailPage extends StatelessWidget {
  const TransitionDetailPage({
    super.key,
    required this.transitionType,
    required this.isFullscreen,
    this.level = 1,
  });

  final AdaptivePageTransitionType transitionType;
  final bool isFullscreen;
  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final router = AdaptiveRouter.of(context);
    final meta = findTransitionPresetMeta(transitionType.name);
    final modePrefix = isFullscreen ? 'fullscreen' : 'branch';
    final nextLevelPath =
        '${RouterNames.transitions}/$modePrefix/${transitionType.name}/sub';

    return Scaffold(
      appBar: AppBar(title: Text('${meta.title} · 第 $level 层')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: level == 1
                    ? [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ]
                    : [
                        colorScheme.tertiaryContainer,
                        colorScheme.primaryContainer,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      child: Icon(meta.icon, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AdaptivePageTransitionType.${transitionType.name}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(meta.description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.category_outlined, size: 16),
                      label: Text(meta.category),
                    ),
                    Chip(
                      avatar: const Icon(Icons.timer_outlined, size: 16),
                      label: Text(
                        '默认时长: ${transitionType.defaultDuration.inMilliseconds}ms',
                      ),
                    ),
                    Chip(
                      avatar: Icon(
                        isFullscreen
                            ? Icons.fullscreen_outlined
                            : Icons.view_column_outlined,
                        size: 16,
                      ),
                      label: Text(isFullscreen ? '全屏根路由模式' : '分支路由模式'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '互动测试',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    level == 1
                        ? '点击下方按钮可继续推入第 2 层页面，观察当前第 1 层页面的退让动画（secondaryAnimation，如视差平移、共享轴偏移或 FadeThrough 缩放淡出），或点击返回按钮观察逆向退场动画。'
                        : '当前位于第 2 层子页面，点击下方返回按钮可观察退场（Reverse Transition）动画并回到第 1 层。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (level == 1)
                        FilledButton.icon(
                          onPressed: () => router.pushNamed(nextLevelPath),
                          icon: const Icon(Icons.layers_outlined),
                          label: const Text('再推入下一层 (测试二级联动)'),
                        ),
                      FilledButton.tonalIcon(
                        onPressed: () => router.maybePop(),
                        icon: const Icon(Icons.arrow_back_outlined),
                        label: const Text('返回上一页 (查看退场动画)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '路由配置示例',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      '// 方式 1：使用内置枚举预设\n'
                      'AdaptiveRoute(\n'
                      '  path: \'detail\',\n'
                      '  transitionType: AdaptivePageTransitionType.${transitionType.name},\n'
                      '  transitionDuration: const Duration(milliseconds: ${transitionType.defaultDuration.inMilliseconds}),\n'
                      '  builder: (context, state) => const DetailPage(),\n'
                      ');\n\n'
                      '// 方式 2：使用可调参构建器工厂\n'
                      'AdaptiveRoute(\n'
                      '  path: \'detail\',\n'
                      '  transitionsBuilder: ${meta.factoryCode},\n'
                      '  builder: (context, state) => const DetailPage(),\n'
                      ');',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
