---
name: xue-hua-adaptive-sliding-layout-routing
description: >-
  Author a xue_hua_adaptive_sliding_layout route table: AdaptiveRoute,
  AdaptiveShellRoute, AdaptiveBranch, :param paths, nested routes, redirect,
  onExit, title, fullscreen / fullscreenDialog, RouteRegistry matching, and
  AdaptiveRouteState. Use when adding or editing routes, redirects, or titles.
license: Apache-2.0
---

# Routing: route table, matching, state

Import the barrel only. Path / pattern API: [references/paths.md](references/paths.md). Route types: [references/route-types.md](references/route-types.md). Typedefs: [references/typedefs.md](references/typedefs.md). Builder state: [references/route-state.md](references/route-state.md). Match objects / `RouteRegistry`: [references/match.md](references/match.md).

## Guidelines

* One table is the URL, the page stack, and the panes. First declared match wins. Child `path` values are **relative** unless they start with `/` (absolute, parent ignored).
* `AdaptiveRoute` requires a non-empty `path` and at least one of `builder` or `redirect` (assert).
* At most one `AdaptiveShellRoute`, and only at the top of `AdaptiveRouter.routes`. Extra or nested shells throw `StateError`. Put more tabs in `branches`.
* `AdaptiveBranch.routes` must be non-empty. If the first path contains `:param`, pass `initialLocation` yourself; otherwise it defaults to that first path (normalized, leading `/`).
* `:name` is a path segment. Values are `Uri.decodeComponent`'d on match and `Uri.encodeComponent`'d on `expand` / `namedLocation`. There is no `*` splat.
* `AdaptiveRoute.name` is optional, global, and unique (`ArgumentError` on duplicates). It is **not** the location. `namedLocation` expands it; `*Named` verbs take a location string.
* `title` runs **once at match time** with no `BuildContext`. `state.fullPath` is the pattern; `state.uri` has the query. Localize with `lookupAppLocalizations(locale)` / `Intl.defaultLocale`, or write `AdaptivePaneScope.maybeOf(context)?.title.value` from the page when you need context or a live locale.
* `fullscreen: true` or `fullscreenDialog: true` ⇒ `onRootNavigator` ⇒ root `Navigator` at every width (login, photo, compose). `hidesBottomBarWhenPushed` (default `true`) only covers the compact bottom bar; medium rail and expanded panes ignore it. Branch roots and root-navigator pages ignore it.
* `builder` + optional `transitionsBuilder` replace go_router `pageBuilder`. Wide panes need a `Widget`, not a `Page`. `transitionsBuilder` applies on the **root** navigator only; pane pages ignore it.
* Top-level `AdaptiveRouter.redirect` runs first, then each matched route’s `redirect` in stack order. A non-null return whose path+query differs starts another hop, up to `redirectLimit` (5). Loops hit `errorBuilder`.
* `onExit` runs for `maybePop`, system back, browser back, and `applyParsed`, **after** the page `PopScope`. `pop` / `pushReplacementNamed` / `pushNamedAndRemoveUntil` skip it.
* Unmatched URIs become `AdaptiveRouteMatchList.notFound` (`error: Exception('No routes for ${uri.path}')`) and `errorBuilder`.

## Examples

### Nested mail stack

```dart
AdaptiveBranch(routes: [
  AdaptiveRoute(
    path: '/mail',
    title: (_) => 'Mail',
    builder: (context, state) => const MailFoldersPage(),
    routes: [
      AdaptiveRoute(
        path: ':folder',
        builder: (context, state) =>
            FolderPage(folder: state.pathParameters['folder']!),
        routes: [
          AdaptiveRoute(
            path: ':threadId',
            name: 'thread',
            title: (s) => 'Thread ${s.pathParameters['threadId']}',
            builder: (context, state) =>
                ThreadPage(id: state.pathParameters['threadId']!),
          ),
        ],
      ),
    ],
  ),
]),
```

`/mail/inbox/42` matches three pages: `/mail`, `/mail/inbox`, `/mail/inbox/42`. Below 840 that is a `Navigator` stack; at or above 840 the last two sit in `SlidingPaneViewport`.

### Redirect-only root + auth gate

```dart
AdaptiveRoute(path: '/', redirect: (_, _) => '/onboarding'),

// On AdaptiveRouter:
redirect: (context, state) {
  if (state.uri.path.startsWith('/settings/account') && !signedIn.value) {
    return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
  }
  return null;
},
```

### Overlay photo with custom transition

```dart
AdaptiveRoute(
  path: '/photo/:id',
  name: 'photo',
  fullscreen: true,
  opaque: false,
  barrierColor: Colors.black54,
  barrierDismissible: true,
  transitionsBuilder: (context, animation, secondary, child) {
    return FadeTransition(opacity: animation, child: child);
  },
  builder: (context, state) => PhotoPage(id: state.pathParameters['id']!),
),
```

### Confirm leave (`onExit`)

```dart
AdaptiveRoute(
  path: ':id/edit',
  onExit: (context, state) async {
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: AdaptivePaneScope.maybeOf(context) != null,
      builder: (context) => AlertDialog(
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
        ],
      ),
    );
    return ok ?? false;
  },
  builder: (context, state) => const EditPage(),
)
```

Use `maybePop` (AppBar back, system back, Escape) so `onExit` runs. `pop()` skips it.

### Read `AdaptiveRouteState`

```dart
final state = AdaptiveRouteState.of(context);
state.uri;                 // current router location, includes query
state.matchedLocation;     // this layer's path, e.g. /mail/inbox/42
state.fullPath;            // pattern, e.g. /mail/:folder/:threadId
state.pathParameters;      // {'folder': 'inbox', 'threadId': '42'}
state.queryParameters;     // URI query, already strings
state.arguments;           // pushNamed(..., arguments:)
state.name;                // AdaptiveRoute.name, or null
```
