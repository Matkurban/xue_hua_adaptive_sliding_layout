import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/data/auth.dart';

/// 未登录时默认回到的主页。
const String _home = '/mail';

/// 给 [path] 带上 `?from=`，为空则不带。
String _withFrom(String path, String? from) {
  return Uri(
    path: path,
    queryParameters: (from == null || from.isEmpty) ? null : {'from': from},
  ).toString();
}

/// 启动首屏（`/onboarding`，fullscreen）：登录 / 注册 / 直接进入主页。
///
/// 登录、注册用 `pushNamed`（可返回本页）；进入主页用
/// `pushNamedAndRemoveUntil(_home, (_) => false)` 按 URL 重建，本页出栈。
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.view_sidebar_outlined, size: 72, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                'Adaptive Sliding Layout',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              FilledButton(
                key: const Key('onboarding-login'),
                onPressed: () => router.pushNamed('/login'),
                child: const Text('Log in'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('onboarding-register'),
                onPressed: () => router.pushNamed('/register'),
                child: const Text('Register'),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('onboarding-home'),
                onPressed: () =>
                    router.pushNamedAndRemoveUntil(_home, (_) => false),
                child: const Text('Enter home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 全屏登录（`/login`）。“Sign in” 置 [signedIn] 后回跳 `?from=`（缺省主页）；
/// “Register” 用 `pushReplacementNamed` 换到注册页并保留 `from`。
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AuthPage(
      title: 'Sign in',
      primaryKey: Key('sign-in'),
      primaryLabel: 'Sign in',
      secondaryKey: Key('go-register'),
      secondaryLabel: 'No account? Register',
      secondaryPath: '/register',
    );
  }
}

/// 全屏注册（`/register`）。“Register” 置 [signedIn] 后回跳 `?from=`（缺省主页）；
/// “Sign in” 用 `pushReplacementNamed` 换到登录页并保留 `from`。
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AuthPage(
      title: 'Register',
      primaryKey: Key('register-submit'),
      primaryLabel: 'Register',
      secondaryKey: Key('go-login'),
      secondaryLabel: 'Have an account? Sign in',
      secondaryPath: '/login',
    );
  }
}

/// [LoginPage] 与 [RegisterPage] 共用的骨架：AppBar + 主按钮 + 切换链接。
///
/// 自己从 [AdaptiveRouteState] 读 `?from=`：主按钮把 [signedIn] 置 true 并
/// `pushNamedAndRemoveUntil(from ?? 主页, (_) => false)`；副按钮
/// `pushReplacementNamed(secondaryPath + from)`，登录 ↔ 注册互换不增加栈深。
///
/// - [title]：AppBar 标题。
/// - [primaryKey] / [primaryLabel]：主按钮（登录 / 注册）的 key 与文案，
///   文案后会拼上 “and return to …”。
/// - [secondaryKey] / [secondaryLabel] / [secondaryPath]：切换链接的 key、
///   文案与目标路径（`/register` 或 `/login`）。
class _AuthPage extends StatelessWidget {
  const _AuthPage({
    required this.title,
    required this.primaryKey,
    required this.primaryLabel,
    required this.secondaryKey,
    required this.secondaryLabel,
    required this.secondaryPath,
  });

  final String title;
  final Key primaryKey;
  final String primaryLabel;
  final Key secondaryKey;
  final String secondaryLabel;
  final String secondaryPath;

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    final from = AdaptiveRouteState.of(context).queryParameters['from'];
    final target = (from == null || from.isEmpty) ? _home : from;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              key: primaryKey,
              onPressed: () {
                signedIn.value = true;
                router.pushNamedAndRemoveUntil(target, (_) => false);
              },
              child: Text('$primaryLabel and return to $target'),
            ),
            const SizedBox(height: 12),
            TextButton(
              key: secondaryKey,
              onPressed: () =>
                  router.pushReplacementNamed(_withFrom(secondaryPath, from)),
              child: Text(secondaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
