import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/data/auth.dart';

/// 示例主题，Settings → Appearance 可切换。
final Signal<ThemeMode> demoThemeMode = signal(ThemeMode.system);

/// 双栏卡片装饰。true 走 [AdaptiveShellRoute.paneBuilder] 的卡片，false 平铺。
final Signal<bool> paneCardStyle = signal(true);

/// Settings 根。Account 受 redirect 保护。
class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            key: const Key('open-account'),
            title: const Text('Account'),
            subtitle: const Text('redirect → /login?from= when signed out'),
            onTap: () => router.pushNamed('/settings/account'),
          ),
          ListTile(
            key: const Key('open-appearance'),
            title: const Text('Appearance'),
            subtitle: const Text('theme + sash + paneBuilder card/flat'),
            onTap: () => router.pushNamed('/settings/appearance'),
          ),
          ListTile(
            key: const Key('open-about'),
            title: const Text('About'),
            subtitle: const Text('state.uri / query / arguments + 404 link'),
            onTap: () =>
                router.pushNamed('/settings/about', arguments: 'from-settings'),
          ),
        ],
      ),
    );
  }
}

/// 登录后才进得来。登出后 [AdaptiveRouter.refresh] 再跑 redirect。
class SettingsAccountPage extends StatelessWidget {
  const SettingsAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Center(
        child: FilledButton(
          key: const Key('sign-out'),
          onPressed: () {
            signedIn.value = false;
            router.refresh();
          },
          child: const Text('Sign out and refresh()'),
        ),
      ),
    );
  }
}

/// 主题与分割比例。
class SettingsAppearancePage extends StatelessWidget {
  const SettingsAppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = AdaptiveShellScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: SignalBuilder(
        builder: (context) {
          final mode = demoThemeMode.value;
          final card = paneCardStyle.value;
          return ListView(
            children: [
              ListTile(
                title: const Text('System'),
                selected: mode == ThemeMode.system,
                onTap: () => demoThemeMode.value = ThemeMode.system,
              ),
              ListTile(
                title: const Text('Light'),
                selected: mode == ThemeMode.light,
                onTap: () => demoThemeMode.value = ThemeMode.light,
              ),
              ListTile(
                title: const Text('Dark'),
                selected: mode == ThemeMode.dark,
                onTap: () => demoThemeMode.value = ThemeMode.dark,
              ),
              ListTile(
                title: Text(
                  'width=${shell?.width.toStringAsFixed(0)}  '
                  'mode=${shell == null
                      ? '-'
                      : shell.isCompact
                      ? 'compact'
                      : shell.isMedium
                      ? 'medium'
                      : 'expanded'}',
                ),
              ),
              ListTile(
                key: const Key('pane-style-card'),
                title: const Text('Pane style: Card'),
                subtitle: const Text('paneBuilder wraps each column in a card'),
                selected: card,
                onTap: () => paneCardStyle.value = true,
              ),
              ListTile(
                key: const Key('pane-style-flat'),
                title: const Text('Pane style: Flat'),
                subtitle: const Text(
                  'paneBuilder returns the column unwrapped',
                ),
                selected: !card,
                onTap: () => paneCardStyle.value = false,
              ),
              ListTile(
                key: const Key('reset-sash'),
                title: const Text('Reset sash to 0.5'),
                onTap: () => shell?.leftPaneFraction.value = 0.5,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 展示 [AdaptiveRouteState] 并跳到不存在的路径。
class SettingsAboutPage extends StatelessWidget {
  const SettingsAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AdaptiveRouteState.of(context);
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('uri=${state.uri}'),
          Text('matched=${state.matchedLocation}'),
          Text('query=${state.queryParameters}'),
          Text('arguments=${state.arguments}'),
          ListTile(
            key: const Key('open-404'),
            title: const Text('Open missing route'),
            subtitle: const Text('errorBuilder'),
            onTap: () => router.pushNamed('/this-does-not-exist'),
          ),
        ],
      ),
    );
  }
}
