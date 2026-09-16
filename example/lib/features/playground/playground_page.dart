import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router.dart';

/// 每个 Navigator 同名动词一个按钮，并实时显示栈与 URL。
class PlaygroundPage extends StatelessWidget {
  const PlaygroundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Playground')),
      body: SignalBuilder(
        builder: (context) {
          final list = router.matches.value;
          final stack = [
            for (final match in list.matches) match.matchedLocation,
          ].join(' → ');
          return ListView(
            key: const Key('playground-list'),
            children: [
              ListTile(
                title: Text('URL ${router.location.value}'),
                subtitle: Text('stack: $stack\ncanPop: ${router.canPop()}'),
              ),
              _item(
                key: 'pg-push-inbox',
                title: 'pushNamed /mail/inbox',
                subtitle: 'same-branch prefix extend',
                onTap: () => router.pushNamed('/mail/inbox'),
              ),
              _item(
                key: 'pg-push-photo',
                title: 'pushNamed /photo/pg',
                subtitle: 'fullscreen overlay',
                onTap: () => router.pushNamed('/photo/pg'),
              ),
              _item(
                key: 'pg-push-color',
                title: 'pushNamed /playground/color',
                subtitle: 'await result (color picker)',
                onTap: () async {
                  final color = await router.pushNamed<Color>(
                    '/playground/color',
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('result=$color')),
                  );
                },
              ),
              _item(
                key: 'pg-replace',
                title: 'pushReplacementNamed /playground/replaced',
                subtitle: 'swap stack top',
                onTap: () =>
                    router.pushReplacementNamed('/playground/replaced'),
              ),
              _item(
                key: 'pg-remove-until',
                title: 'pushNamedAndRemoveUntil /mail (_)=>false',
                subtitle: 'rebuild from URL',
                onTap: () => router.pushNamedAndRemoveUntil(
                  '/mail',
                  (_) => false,
                ),
              ),
              _item(
                key: 'pg-pop-and-push',
                title: 'popAndPushNamed /playground/replaced',
                onTap: () => router.popAndPushNamed('/playground/replaced'),
              ),
              _item(
                key: 'pg-pop',
                title: 'pop',
                onTap: () => router.pop(),
              ),
              _item(
                key: 'pg-maybe-pop',
                title: 'maybePop',
                subtitle: 'asks onExit when present',
                onTap: () => router.maybePop(),
              ),
              _item(
                key: 'pg-pop-until',
                title: 'popUntil playground root',
                onTap: () => router.popUntil(
                  (match) => match.matchedLocation == '/playground',
                ),
              ),
              _item(
                key: 'pg-cross-tab',
                title: 'pushNamed /mail/inbox/3',
                subtitle: 'cross-branch rebuild',
                onTap: () => router.pushNamed('/mail/inbox/3'),
              ),
              _item(
                key: 'pg-timer',
                title: 'router.pushNamed after 1s (no context)',
                onTap: () {
                  Timer(const Duration(seconds: 1), () {
                    appRouter.pushNamed('/mail');
                  });
                },
              ),
              _item(
                key: 'pg-fade',
                title: 'pushNamed /playground/fade',
                subtitle: 'custom transitionsBuilder',
                onTap: () => router.pushNamed('/playground/fade'),
              ),
              _item(
                key: 'pg-dialog',
                title: 'showDialog',
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => const AlertDialog(
                      title: Text('Dialog'),
                      content: Text('Uses the root overlay by default.'),
                    ),
                  );
                },
              ),
              _item(
                key: 'pg-sheet-local',
                title: 'showModalBottomSheet (local navigator)',
                subtitle: 'clipped by the pane — compare with root',
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => const SizedBox(
                      height: 160,
                      child: Center(child: Text('local sheet')),
                    ),
                  );
                },
              ),
              _item(
                key: 'pg-sheet-root',
                title: 'showModalBottomSheet(useRootNavigator: true)',
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    useRootNavigator: true,
                    builder: (context) => const SizedBox(
                      height: 160,
                      child: Center(child: Text('root sheet')),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('PopupMenuButton'),
                trailing: PopupMenuButton<String>(
                  key: const Key('pg-menu'),
                  useRootNavigator: AdaptivePaneScope.maybeOf(context) != null,
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'a', child: Text('Pinned')),
                  ],
                ),
              ),
              const ListTile(
                subtitle: Text(
                  'Escape pops the sliding stack. Browser back uses maybePop.',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _item({
    required String key,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      key: Key(key),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      onTap: onTap,
    );
  }
}

/// `await pushNamed<Color>` 的结果页。
class ColorPickerPage extends StatelessWidget {
  const ColorPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pick a color')),
      body: ListView(
        children: [
          ListTile(
            key: const Key('pick-red'),
            title: const Text('Red'),
            onTap: () => router.pop(Colors.red),
          ),
          ListTile(
            key: const Key('pick-blue'),
            title: const Text('Blue'),
            onTap: () => router.pop(Colors.blue),
          ),
        ],
      ),
    );
  }
}

class PlaygroundReplacedPage extends StatelessWidget {
  const PlaygroundReplacedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Replaced')),
      body: const Center(child: Text('Stack top after pushReplacementNamed')),
    );
  }
}

class PlaygroundFadePage extends StatelessWidget {
  const PlaygroundFadePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fade')),
      body: const Center(child: Text('Custom transitionsBuilder')),
    );
  }
}
