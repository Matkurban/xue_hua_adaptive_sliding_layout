import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_names.dart';

class SplashPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final AdaptiveRouter router = AdaptiveRouter.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Splash Page')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.view_sidebar_outlined,
                size: 72,
                color: scheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Adaptive Sliding Layout',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              FilledButton(
                key: const Key('onboarding-login'),
                onPressed: () => router.pushNamed(RouterNames.login),
                child: const Text('Log in'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('onboarding-register'),
                onPressed: () => router.pushNamed(RouterNames.register),
                child: const Text('Register'),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('onboarding-home'),
                onPressed: () => router.pushNamedAndRemoveUntil(
                  RouterNames.home,
                  (_) => false,
                ),
                child: const Text('Enter home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
