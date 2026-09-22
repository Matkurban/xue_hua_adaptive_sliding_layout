import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_names.dart';

class MinePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: .symmetric(vertical: 24),
        children: [
          Padding(
            padding: .symmetric(horizontal: 16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(
                    'https://picsum.photos/seed/mine/200/200',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text('林晓', style: theme.textTheme.titleLarge),
                      SizedBox(height: 4),
                      Text('linxiao@example.com'),
                      Text('13800001111'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: .horizontal,
            padding: .symmetric(horizontal: 16),
            child: Row(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => router.pushNamed(RouterNames.theme),
                  child: const Text('主题'),
                ),
                FilledButton.tonal(
                  onPressed: () => router.pushNamed(RouterNames.account),
                  child: const Text('账号'),
                ),
                FilledButton.tonal(
                  onPressed: () => router.pushNamed(RouterNames.about),
                  child: const Text('关于'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
