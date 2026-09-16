import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/data/auth.dart';

/// 全屏登录。登录后 `pushNamedAndRemoveUntil(from, (_) => false)` 回跳。
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    final from = AdaptiveRouteState.of(context).queryParameters['from'];
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Center(
        child: FilledButton(
          key: const Key('sign-in'),
          onPressed: () {
            signedIn.value = true;
            final target = (from == null || from.isEmpty) ? '/mail' : from;
            router.pushNamedAndRemoveUntil(target, (_) => false);
          },
          child: Text('Sign in and return to ${from ?? '/mail'}'),
        ),
      ),
    );
  }
}

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
              onPressed: () =>
                  router?.pushNamedAndRemoveUntil('/mail', (_) => false),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 全屏照片，叠在根 Navigator 上。
class PhotoPage extends StatelessWidget {
  const PhotoPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image, size: 96, color: Theme.of(context).colorScheme.primary),
            Text('photo-$id', key: const Key('photo-id')),
          ],
        ),
      ),
    );
  }
}

class EmptyDetail extends StatelessWidget {
  const EmptyDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.web_asset_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
