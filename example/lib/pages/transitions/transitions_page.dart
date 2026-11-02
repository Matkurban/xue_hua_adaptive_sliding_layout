import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/pages/transitions/transition_preset_meta.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_names.dart';

/// 过渡效果展示 Tab 页：可分类筛选并点击查看全部 18 种内置页面过渡效果。
class TransitionsPage extends StatefulWidget {
  const TransitionsPage({super.key});

  @override
  State<TransitionsPage> createState() => _TransitionsPageState();
}

class _TransitionsPageState extends State<TransitionsPage> {
  String _selectedCategory = '全部';

  /// 双栏宽屏下点击卡片默认使用全屏路由（`fullscreen: true`）以直接展示完整页面过场动画；
  /// 关闭时在双栏下走右侧分栏滑入，单栏下始终走页面过场动画。
  bool _preferFullscreenOnExpanded = true;

  static const List<String> _categories = <String>[
    '全部',
    '基础与平台',
    '方向滑动',
    'Material 共享轴',
    '缩放 / 旋转 / 展开',
    '3D 透视翻转',
  ];

  void _openPreview(
    BuildContext context,
    AdaptivePageTransitionType type, {
    required bool fullscreen,
  }) {
    final modePrefix = fullscreen ? 'fullscreen' : 'branch';
    AdaptiveRouter.of(context)
        .pushNamed('${RouterNames.transitions}/$modePrefix/${type.name}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpanded = AdaptiveShellScope.maybeOf(context)?.isExpanded ?? false;

    final filtered = _selectedCategory == '全部'
        ? transitionPresets
        : [
            for (final item in transitionPresets)
              if (item.category == _selectedCategory) item,
          ];

    return Scaffold(
      appBar: AppBar(title: const Text('页面过渡效果 (18 种)')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Material(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                child: SwitchListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: const Text('双栏宽屏下点击卡片直接全屏演示过场动画'),
                  subtitle: const Text('开启时在根 Navigator 上播放完整过渡动画；关闭时在右栏内打开子页'),
                  value: _preferFullscreenOnExpanded,
                  onChanged: (value) {
                    setState(() => _preferFullscreenOnExpanded = value);
                  },
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              spacing: 8,
              children: [
                for (final category in _categories)
                  ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = filtered[index];
                final useFullscreen = isExpanded && _preferFullscreenOnExpanded;
                return Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openPreview(
                      context,
                      item.type,
                      fullscreen: useFullscreen,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                            child: Icon(item.icon, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.title,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${item.type.defaultDuration.inMilliseconds}ms',
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'AdaptivePageTransitionType.${item.type.name}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isExpanded)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: '在右栏打开',
                                  onPressed: () => _openPreview(
                                    context,
                                    item.type,
                                    fullscreen: false,
                                  ),
                                  icon: const Icon(
                                    Icons.view_column_outlined,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  tooltip: '全屏播放过渡动画',
                                  onPressed: () => _openPreview(
                                    context,
                                    item.type,
                                    fullscreen: true,
                                  ),
                                  icon: const Icon(
                                    Icons.play_circle_outline,
                                    size: 22,
                                  ),
                                ),
                              ],
                            )
                          else
                            Icon(
                              Icons.chevron_right,
                              color: colorScheme.outline,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
