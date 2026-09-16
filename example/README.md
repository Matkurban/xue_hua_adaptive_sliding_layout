# Example

Host demo for [`xue_hua_adaptive_sliding_layout`](../README.md) 3.0 ([中文](../README.zh-CN.md)).

**[Live web demo](https://matkurban.github.io/xue_hua_adaptive_sliding_layout/)** — the top bar pins Phone / Foldable / Tablet / Desktop widths so a desktop visitor can see every breakpoint without resizing the window.

This app **is** the integration template: copy [`lib/router.dart`](lib/router.dart).

## Run

```bash
flutter run -d chrome
flutter test
flutter build web --release
```

`MaterialApp.router` lives in [`lib/main.dart`](lib/main.dart). [`DemoFrame`](lib/frame/demo_frame.dart) wraps the router output. [`AppShell`](lib/shell/app_shell.dart) uses `NavigationBar` under 600px and `NavigationRail` otherwise; tapping the current tab calls `goBranch(i, initialLocation: true)`.

## Scenarios

Each page subtitle names the API it demonstrates.

| Branch / route | Coverage |
| --- | --- |
| Mail `/mail → :folder → :threadId → reply` | 4-deep stack, two-pane slide, breadcrumbs `popUntil`, `pushReplacementNamed` folder swap, `pushNamed` slide vs stack-on-top, static `title` + async `AdaptivePaneScope.title`, `?ref=` + `arguments`, reply keep-alive, fullscreen `/photo/:id` |
| Contacts `/contacts?q= → :id → edit` | search writes `q` into the URL, `namedLocation`, `await pushNamed<bool>` + `pop(true)`, `onExit` (`maybePop` blocked vs `pop` forced), avatar photo overlay, sash |
| Settings `/settings → account \| appearance \| about` | `redirect` to `/login?from=`, return via `pushNamedAndRemoveUntil`, sign-out `refresh()`, theme / sash / `paneBuilder` card-flat, `errorBuilder` 404 |
| Playground `/playground` | every Navigator verb, fullscreen, fullscreenDialog color picker, result Future, custom `transitionsBuilder`, no-context `router.pushNamed`, dialog / sheet `useRootNavigator` contrast, Escape |
| Onboarding `/onboarding → /login \| /register` | app starts here; log in / register / enter home, login ↔ register `pushReplacementNamed` keeps `?from=`, `pushNamedAndRemoveUntil` into the shell |
| Top-level | `/` redirect to `/onboarding`, `/login`, `/register`, `/photo/:id`, unknown path |

On phones every page below a branch root hides the `NavigationBar` (`hidesBottomBarWhenPushed`, the package default); desktop keeps two panes.

Tests in `test/` pump the same router at 400 and 1200 width (onboarding / login / register, deep stack, replace, `onExit`, login round-trip, 404, overlay, hidden bottom bar, cross-branch `pushNamed`, branch memory, `setNewRoutePath`, sash drag). `widget_test.dart` boots the real `DemoApp`.
