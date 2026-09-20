---
name: xue-hua-adaptive-sliding-layout-setup
description: >-
  Wire xue_hua_adaptive_sliding_layout into a Flutter app: AdaptiveRouter
  constructor, MaterialApp.router, of/maybeOf, location/matches signals,
  top-level redirect, errorBuilder, refresh, and 2.x / go_router migration.
  Use when adding the package, creating the router, or replacing go_router.
license: Apache-2.0
---

# Setup: AdaptiveRouter + MaterialApp.router

Package: `xue_hua_adaptive_sliding_layout` (3.1.x). Import only the barrel:

```dart
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
```

Do not import `src/`. `NavigationEngine` and `AdaptiveShellHost` are not public.

Full constructor / lookup / signal / resolve API: [references/adaptive-router.md](references/adaptive-router.md), [references/adaptive-router-scope.md](references/adaptive-router-scope.md).

Route table → `xue-hua-adaptive-sliding-layout-routing`. Navigator verbs → `xue-hua-adaptive-sliding-layout-navigation`. Panes / breakpoints → `xue-hua-adaptive-sliding-layout-layout`.

## Guidelines

* Hold one `AdaptiveRouter` on the host (top-level final or a widget field). Pass it as `MaterialApp.router(routerConfig: router)`. There is no service locator and no `context.go` / `context.pushNamed` extension.
* `AdaptiveRouter` implements `RouterConfig<AdaptiveRouteMatchList>`. The constructor builds `routeInformationProvider`, `routeInformationParser`, `routerDelegate`, and `backButtonDispatcher`.
* From a page, take the instance with `AdaptiveRouter.of(context)`. Use `maybeOf` only when the widget may sit outside the router subtree.
* Subscribe to `router.location`, `router.matches`, `router.currentBranch`, and `router.leftPaneFraction` with `SignalBuilder` from `signals_flutter`.
* Call `router.refresh()` after auth (or any other input that top-level / per-route `redirect` reads) changes.
* Provide `errorBuilder` for unmatched locations and redirect loops (`redirectLimit`, default 5).
* `routeName` on every `*Named` verb is a **location** (`/mail/inbox`), not `AdaptiveRoute.name`. Build named locations with `router.namedLocation(...)`.
* The platform `defaultRouteName` wins over `initialLocation` when it is non-empty and not `/`. Web uses the Flutter hash URL strategy (`/#/mail`).
* One `AdaptiveShellRoute`, top-level only. No nested shells, no `restorable*`, no `push(Route)`.
* Crossing `expandedMinWidth` (840) rebuilds page `State` (Navigator tree ↔ viewport tree). Keep durable state in the URL, a signal, or a host store.

## Examples

### Host the router

```dart
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

final router = AdaptiveRouter(
  initialLocation: '/mail',
  errorBuilder: (context, state) => Text('Missing ${state.uri}'),
  routes: [
    AdaptiveShellRoute(
      builder: (context, shell, child) {
        return Scaffold(
          body: child,
          bottomNavigationBar: shell.isCompact
              ? NavigationBar(
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: shell.goBranch,
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.mail), label: 'Mail'),
                    NavigationDestination(icon: Icon(Icons.people), label: 'Contacts'),
                  ],
                )
              : null,
        );
      },
      branches: [
        AdaptiveBranch(routes: [
          AdaptiveRoute(
            path: '/mail',
            title: (_) => 'Mail',
            builder: (context, state) => const MailPage(),
          ),
        ]),
        AdaptiveBranch(routes: [
          AdaptiveRoute(
            path: '/contacts',
            builder: (context, state) => const ContactsPage(),
          ),
        ]),
      ],
    ),
  ],
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);
  }
}
```

The host may keep `router` as a field and call `router.pushNamed(...)` with no `BuildContext`.

### Read location in UI

```dart
SignalBuilder(
  builder: (context) {
    final location = AdaptiveRouter.of(context).location.value;
    return Text(location);
  },
);
```

### Top-level redirect + refresh

```dart
final router = AdaptiveRouter(
  initialLocation: '/mail',
  redirect: (context, state) {
    if (state.uri.path.startsWith('/settings/account') && !signedIn.value) {
      return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
    }
    return null;
  },
  routes: routes,
);

// After sign-in / sign-out:
signedIn.value = false;
router.refresh();
```

### Leave the app at a tab root

Put `PopScope(canPop: false)` in the **shell builder** (or a tab root). System back then hits `onPopInvokedWithResult(false)`. Show the dialog with `showDialog(useRootNavigator: false)` so it shares the shell navigator. Confirm with `SystemNavigator.pop()`. Escape at the root does not run this path.

### Migrate from go_router

| go_router | this package |
| --- | --- |
| `GoRoute` | `AdaptiveRoute` |
| `StatefulShellRoute.indexedStack` | `AdaptiveShellRoute` + `AdaptiveBranch` |
| `context.go(loc)` | `router.pushNamedAndRemoveUntil(loc, (_) => false)` |
| `context.push(loc)` | `router.pushNamed(loc)` |
| `extra` | `arguments` |
| `GoRouterState` | `AdaptiveRouteState` |
| `pageBuilder` | `builder` + optional `transitionsBuilder` |
| `context.go` / `context.pop` extensions | `AdaptiveRouter.of(context)` only |

### Migrate from 2.x

| 2.x | 3.x |
| --- | --- |
| `SlidingShell` + `MultiColumnScaffold` + `AdaptiveNavigator` | one `AdaptiveRouter` + `MaterialApp.router` |
| `extra` | `arguments` |
| `inSlidingWindow(context)` | `AdaptivePaneScope.maybeOf(context) != null` |
| `SlidingPageTitle.report` | `AdaptivePaneScope.maybeOf(context)?.title.value = …` |
| `SlidingActions.pop` | `AdaptiveRouter.of(context).maybePop()` |

No compatibility shim.
