import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_names.dart';

/// [AdaptiveRouter.errorBuilder] 使用的 404 页。
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No routes for $uri', key: const Key('not-found-uri')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => router?.pushNamedAndRemoveUntil(
                RouterNames.home,
                (_) => false,
              ),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    );
  }
}
