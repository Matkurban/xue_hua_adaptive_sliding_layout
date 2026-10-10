# xue_hua_adaptive_sliding_layout

- [中文文档](README.zh-CN.md)
- **[Documentation](https://matkurban.github.io/xue_hua_adaptive_sliding_layout/docs/)**
- **[Live demo](https://matkurban.github.io/xue_hua_adaptive_sliding_layout/example/)**

Declarative adaptive routing for Flutter. **One route table** maps a URL to a page stack and a 1- or 2-column sliding layout. Call sites look like `Navigator`: `AdaptiveRouter.of(context).pushNamed(...)`.

The host holds the `AdaptiveRouter` instance — no service locator. Extra dependencies: `signals_flutter`, `material_ui`.

- [60-second start](#60-second-start)
- [URL → stack → panes](#url--stack--panes)
- [Route table](#route-table)
- [Navigation verbs](#navigation-verbs)
- [Reading state](#reading-state)
- [Customizing the UI](#customizing-the-ui)
- [Layout without a router](#layout-without-a-router)
- [Example scenarios](#example-scenarios)
- [Migrating from 2.x](#migrating-from-2x)
- [Migrating from go_router](#migrating-from-go_router)
- [Caveats](#caveats)
- [Package skills](#package-skills)

## 60-second start

```dart
final router = AdaptiveRouter(
  initialLocation: '/mail',
  routes: [
    AdaptiveShellRoute(
      builder: (context, shell, child) {
        if (!shell.isCompact) return Scaffold(body: child);
        return AdaptiveShellChrome(
          bottomNavigationBar: (context) => NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) => shell.goBranch(i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.mail), label: 'Mail'),
              NavigationDestination(icon: Icon(Icons.people), label: 'Contacts'),
            ],
          ),
          child: child,
        );
      },
      branches: [
        AdaptiveBranch(routes: [
          AdaptiveRoute(
            path: '/mail',
            title: (_) => 'Mail',
            builder: (context, state) => const MailPage(),
            routes: [
              AdaptiveRoute(
                path: ':folder',
                builder: (context, state) =>
                    FolderPage(folder: state.pathParameters['folder']!),
              ),
            ],
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

MaterialApp.router(routerConfig: router);
```

From a page:

```dart
final router = AdaptiveRouter.of(context);
router.pushNamed('/mail/inbox');
router.pushNamed(
  router.namedLocation('thread', pathParameters: {'folder': 'inbox', 'threadId': '42'}),
  arguments: thread,
);
router.pop();
```

Copy the full table from [`example/lib/router/router_pages.dart`](example/lib/router/router_pages.dart).

## URL → stack → panes

```mermaid
flowchart LR
  URL["URL  /mail/inbox/42/reply"] --> Parser["RouteInformationParser"]
  Parser --> Matches["MatchList  mail, inbox, 42, reply"]
  Matches --> Delegate["RouterDelegate"]
  Delegate --> Shell["AdaptiveShellRoute.builder"]
  Shell --> Width{"window width"}
  Width -->|"< 840  1 column"| Nav["Navigator pages"]
  Width -->|">= 840  2 columns"| Panes["SlidingPaneViewport last 2 panes"]
  Delegate --> Overlay["fullscreen / off-shell routes"]
```

A location such as `/mail/inbox/42/reply` walks the route tree and produces a list of matches. That list **is** the page stack. Below `expandedMinWidth` (default 840) it is a classic `Navigator`. At or above it, the last two matches sit side by side in [`SlidingPaneViewport`](lib/src/layout/sliding_pane_viewport.dart); deeper pages slide older ones off to the left. `fullscreen: true` and `fullscreenDialog: true` matches stack on the **root** Navigator (login, photo, compose dialogs).

Browser back, deep links, and refresh all change the location and take the same path. Web uses the default **hash** strategy (`/#/mail/inbox/42`), so GitHub Pages needs no 404 fallback.

## Route table

| Type                                                          | Role                                                                                                                                                                                                                                                                                                      |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`AdaptiveRouter`](lib/src/router/adaptive_router.dart)       | `RouterConfig<AdaptiveRouteMatchList>`. Verbs + `namedLocation` / `refresh`. Signals: `location`, `matches`, `currentBranch`. `of` / `maybeOf`.                                                                                                                                                           |
| [`AdaptiveRoute`](lib/src/router/adaptive_route.dart)                  | One page. `path`, optional `name`, `builder`, `title`, `fullscreen`, `fullscreenDialog`, `hidesBottomBarWhenPushed`, `opaque`, `barrierColor`, `barrierDismissible`, `transitionsBuilder`, `redirect`, `onExit`, nested `routes`. Child paths are relative; `:param` is one path segment. First match wins. |
| [`AdaptiveShellRoute`](lib/src/router/adaptive_shell_route.dart)             | Tabs + adaptive chrome. One per tree, top-level only. `builder(context, shell, child)`, `branches`, `breakpoints`, sash / breadcrumbs, plus [UI knobs](#customizing-the-ui).                                                                                                                              |
| [`AdaptiveShellChrome`](lib/src/layout/shell_bar.dart)        | Compact bottom bar. `bottomNavigationBar` is a `WidgetBuilder`. The bar is inside the branch page, so a sheet with `useRootNavigator: false` covers it. Do not also set `Scaffold.bottomNavigationBar`.                                                                                                    |
| [`AdaptiveBranch`](lib/src/router/adaptive_branch.dart)                 | One tab. `routes`, optional `initialLocation` / `placeholder`.                                                                                                                                                                                                                                            |
| [`AdaptiveRouteState`](lib/src/router/adaptive_route_state.dart)       | Builder argument, also `AdaptiveRouteState.of(context)`: `uri`, `matchedLocation`, `fullPath`, `name`, `pathParameters`, `queryParameters`, `arguments`, `error`, `pageKey`.                                                                                                                              |
| [`AdaptiveShellState`](lib/src/router/adaptive_shell_state.dart)       | Shell builder argument: `currentIndex`, width / breakpoints, `leftPaneFraction`, `goBranch`.                                                                                                                                                                                                              |
| [`LayoutBreakpoints`](lib/src/layout/layout_breakpoints.dart) | `const` class, defaults `compactMaxWidth: 600`, `expandedMinWidth: 840`.                                                                                                                                                                                                                                  |

`builder` + `transitionsBuilder` supply the page, because wide panes need a `Widget`, not a `Page`.

Top-level `redirect` and per-route `redirect` may return a new location (`FutureOr<String?>`). Loops stop after `redirectLimit` (5) and hit `errorBuilder`.

## Navigation verbs

All names and signatures match [`NavigatorState`](https://api.flutter.dev/flutter/widgets/NavigatorState-class.html). `routeName` is a location. There is no non-named `push(Route)` — every page must be in the table so the URL can express it.

| Call                      | Compact (1 column)                                                                                                                                                                                                                                                                                                                                       | Expanded (2 columns) |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- |
| `pushNamed`               | Push onto the branch `Navigator`, or overlay the root if `fullscreen` / off-shell. Same-branch prefix extends the stack (`/mail` → `/mail/inbox/42` can slide in two panes). Same-branch non-prefix appends the leaf (`/mail/inbox/41` → `/mail/inbox/42` yields `[mail, inbox, 41, 42]`). Other branch: switch tab and rebuild that stack from the URL. |
| `pushReplacementNamed`    | Replace stack top. Same-level swap; the right pane updates in place.                                                                                                                                                                                                                                                                                     |
| `pushNamedAndRemoveUntil` | Pop while the predicate is false, then `pushNamed`. `(_) => false` rebuilds from the URL (deep link, login return, reset tab).                                                                                                                                                                                                                           |
| `popAndPushNamed`         | `pop` then `pushNamed`.                                                                                                                                                                                                                                                                                                                                  |
| `pop`                     | Pop immediately. **Does not** call `onExit`. If a dialog / sheet / menu covers the top page, only that layer is closed.                                                                                                                                                                                                                                  |
| `maybePop`                | Asks the top page's `PopScope` first, then the route's `onExit`. AppBar back, system back, browser back, and Escape use this. At the bottom of the stack `maybePop` is a no-op; system back asks the bottom route's `onExit` before the app exits. Context-free: it only handles the **top pane** plus root / shell popups that cover everything. |
| `popFrom(context)`        | Acts on the layer `context` lives in: inside a dialog / sheet it closes that; inside a page it closes the popup covering that page, or pops the page when it is the top page and uncovered; a non-top page is left alone. **Does not** call `onExit`. With one sheet per pane, the context you pass picks the sheet.                                    |
| `maybePopFrom(context)`   | Consultative `popFrom`: a popup gets its own `PopScope`; a page gets `PopScope` → `onExit`.                                                                                                                                                                                                                                                              |
| `popUntil`                | Pop until the predicate is true, not past the branch root.                                                                                                                                                                                                                                                                                               |
| `canPop`                  | Overlay present, or current branch depth > 1.                                                                                                                                                                                                                                                                                                            |

Tab switches are not a Navigator verb. Use `AdaptiveShellState.goBranch(index, {initialLocation})`. Internally that is `pushNamedAndRemoveUntil` to the branch's last location (or `initialLocation`). Tapping the **current** tab with `initialLocation: true` returns to the branch root — see [`example/lib/shell/app_shell.dart`](example/lib/shell/app_shell.dart).

Helpers: `namedLocation(name, pathParameters:, queryParameters:)` builds a location for the `*Named` verbs; `refresh()` re-runs redirect after auth changes.

`pushNamed` returns a `Future` completed by `pop(result)`.

### Confirm before exit

Put `PopScope(canPop: false)` in the shell `builder` (or a tab root page). System back then calls `onPopInvokedWithResult(false)` so you can show a dialog and `SystemNavigator.pop()`. Use `showDialog(useRootNavigator: false)` so the dialog shares the shell navigator with `PopScope` — a root-navigator dialog would make the next Android back exit the app. Works with Android predictive back. See [`example/lib/shell/app_shell.dart`](example/lib/shell/app_shell.dart). Escape at the root does not trigger this.

## Reading state

```dart
AdaptiveRouter.of(context).location.value;          // '/mail/inbox/42'
AdaptiveRouteState.of(context).pathParameters;      // {'folder': 'inbox', ...}
AdaptivePaneScope.maybeOf(context)?.title.value = subject; // breadcrumbs
AdaptiveShellScope.maybeOf(context)?.isExpanded;
```

[`AdaptivePaneScope.maybeOf`](lib/src/layout/pane_scope.dart) is non-null only inside a two-column pane. Use it instead of 2.x `inSlidingWindow` / `SlidingPageTitle`. Async titles: write `title.value` when the subject arrives — the package no longer walks the element tree for `AppBar.title`.

`AdaptiveRoute.title(state)` runs once at match time and has no `BuildContext`; `state.fullPath` is the full pattern and `state.uri` carries the query. To localize it, use a context-free lookup — gen-l10n's `lookupAppLocalizations(locale)` with `WidgetsBinding.instance.platformDispatcher.locale` (or your own locale signal), or `intl`'s `Intl.defaultLocale`. When you need a context, or the title must follow a live locale switch, set `AdaptivePaneScope.maybeOf(context)?.title.value` from the page instead; a static `title` is not re-evaluated when the locale changes.

Subscribe in UI with `SignalBuilder` (see `signals_flutter`).

To draw titles in **your** chrome instead of the built-in strip, read `AdaptiveRouter.of(context).matches.value.branchMatches` (each match has a `title` signal and `name`).

## Customizing the UI

Use **builders** to replace structure, **value parameters** to tweak numbers. Defaults match the 3.0 first release. Theme colors still come from `Theme.of(context)`. 1-column page transitions use Flutter's `ThemeData.pageTransitionsTheme`.

### Viewport (`SlidingPaneViewport` / `AdaptiveShellRoute`)

| Parameter             | Default                 | Role                                                                   |
| --------------------- | ----------------------- | ---------------------------------------------------------------------- |
| `slideDuration`       | 280ms                   | Column slide                                                           |
| `slideCurve`          | `Curves.easeOutCubic`   | Column slide                                                           |
| `paneBuilder`         | 2-col card / 1-col flat | Wrap each column. `index == panes.length` is the empty right slot      |
| `resizeHandleBuilder` | rounded animated bar | `Widget Function(BuildContext context, bool isHovered)` (since 3.4.0); highlights with `colorScheme.primary` on hover / drag |
| `resizeHandleWidth` | 4 on `AdaptiveShellRoute` | Hit-test width; required on `SlidingPaneViewport` (since 3.4.0) |
| `resizeHandleMargin` | — | Insets the handle independently of its hit area |
| `placeholder`         | outline icon            | Shell-level empty right pane; `AdaptiveBranch.placeholder` wins if set |

### Breadcrumbs

| Parameter                               | Default               | Role                                                       |
| --------------------------------------- | --------------------- | ---------------------------------------------------------- |
| `height`                                | 32                    | Strip height                                               |
| `padding`                               | horizontal 12         | Strip padding                                              |
| `backgroundColor`                       | `surfaceContainerLow` | Strip color                                                |
| `itemBuilder`                           | InkWell + Text        | One crumb                                                  |
| `separatorBuilder`                      | chevron               | Between crumbs                                             |
| `AdaptiveShellRoute.breadcrumbsBuilder` | `AdaptiveBreadcrumbs` | Replace the whole strip (`showBreadcrumbs` still gates it) |
| `escapePops`                            | true                  | Escape calls `maybePop`                                    |

On medium / expanded, nested pages keep the host chrome. On compact, pages below the branch root hide the bottom bar by default (`hidesBottomBarWhenPushed`; set `false` to keep it). That flag is only about pushed pages. A bottom sheet on the tab root covers the bar when the shell uses [`AdaptiveShellChrome`](lib/src/layout/shell_bar.dart) (`useRootNavigator: false`). `Scaffold.bottomNavigationBar` sits outside the branch navigator, so the same sheet leaves the bar visible. `fullscreen` / `fullscreenDialog` cover the shell at every width.

### Overlay routes (`AdaptiveRoute`)

| Parameter                  | Default | Role                                                                                                            |
| -------------------------- | ------- | --------------------------------------------------------------------------------------------------------------- |
| `hidesBottomBarWhenPushed` | true    | Compact only: the pushed page covers the host bottom bar (same name as iOS). Two panes on desktop are untouched |
| `fullscreen`               | false   | Root Navigator at every width, normal transition                                                                 |
| `fullscreenDialog`         | false   | Root Navigator at every width as a Material fullscreen dialog (slide up, close icon)                            |
| `opaque`                   | true    | With `transitionsBuilder`: transparent photo viewer                                                             |
| `barrierColor`             | null    | With `transitionsBuilder`                                                                                       |
| `barrierDismissible`       | false   | Tap the barrier to pop                                                                                          |

See [`example/lib/router/router_pages.dart`](example/lib/router/router_pages.dart) for a `Card` `paneBuilder`, a 32px breadcrumb strip via `breadcrumbsBuilder`, a custom `resizeHandleBuilder`, and a translucent `/home/:id/preview` overlay.

## Layout without a router

[`SlidingPaneViewport`](lib/src/layout/sliding_pane_viewport.dart), [`SlidingPane`](lib/src/layout/pane_scope.dart), and [`AdaptiveBreadcrumbs`](lib/src/layout/breadcrumbs.dart) stay public if you only want the sliding columns.

Breakpoints (window width, not device type):

| Width                      | Band     | Visible columns                                             |
| -------------------------- | -------- | ----------------------------------------------------------- |
| `< compactMaxWidth` (600)  | compact  | 1 — `Navigator` (full-screen stack)                         |
| `600–839`                  | medium   | 1 — same `Navigator`; host uses `shell.isMedium` for chrome |
| `≥ expandedMinWidth` (840) | expanded | 2 — last two panes + optional sash                          |

`ponytail:` the viewport is 1 or 2 columns. Three-plus columns would change `visibleColumnCount` and teach `SlidingPaneViewport` to lay out N panes.

## Example scenarios

[`example/`](example/) is the integration template. On the web demo, the top bar pins Phone 480 / Foldable 720 / Tablet 1023 / Desktop so you do not have to resize the window.

| Area | What it shows | Files |
| --- | --- | --- |
| Auth | Full-screen `/splash`, `/login`, `/register`; top-level `redirect` sends `/mine/account` to `/login?from=` while signed out | [`pages/auth`](example/lib/pages/auth/) |
| Home | Product list → `/home/:id` with a `title` resolved from the id; translucent fullscreen `/home/:id/preview` (`opaque: false`, `barrierDismissible`, fade `transitionsBuilder`) | [`pages/home`](example/lib/pages/home/) |
| Shopping cart | A separate branch with its own stack | [`pages/shopping_cart`](example/lib/pages/shopping_cart/) |
| Contacts | `/contacts/:id` → `edit`; `onExit` confirm dialog with `useRootNavigator: AdaptivePaneScope.maybeOf(context) != null` | [`pages/contacts`](example/lib/pages/contacts/) |
| Mine | Nested `theme` / `account`; `about` as `fullscreenDialog` | [`pages/mine`](example/lib/pages/mine/) |
| Shell / frame | Compact `NavigationBar` in `AdaptiveShellChrome` vs `NavigationRail`, re-tap tab → `goBranch(i, initialLocation: true)`, `PopScope` exit confirm, width presets | [`app_shell.dart`](example/lib/shell/app_shell.dart), [`size_preset_screen.dart`](example/lib/pages/size_preset_screen.dart) |
| Router | Full route table: breadcrumbs, custom `resizeHandleBuilder`, `Card` panes, `errorBuilder` 404 | [`router_pages.dart`](example/lib/router/router_pages.dart) |

```bash
cd example && flutter run -d chrome
cd example && flutter test
```

## Migrating from 2.x

| 2.x                                                                                      | 3.x                                                   |
| ---------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| `SlidingShell` + per-tab `MultiColumnScaffold` + `AdaptiveNavigator` + 9-method fallback | one `AdaptiveRouter` + `MaterialApp.router`           |
| `handlesRoute` / `buildPage` / `resolveTitle`                                            | `AdaptiveRoute` in the table                          |
| `from:` / `openAfter` / `openSecondary`                                                  | URL is the stack (`pushNamed` prefix vs append)       |
| `extra`                                                                                  | `arguments`                                           |
| `inSlidingWindow(context)`                                                               | `AdaptivePaneScope.maybeOf(context) != null`          |
| `SlidingPageTitle.report`                                                                | `AdaptivePaneScope.maybeOf(context)?.title.value = …` |
| `SlidingActions.pop`                                                                     | `AdaptiveRouter.of(context).maybePop()`               |

There is no compatibility shim. See [CHANGELOG](CHANGELOG.md).

## Migrating from go_router

| go_router                               | this package                                        |
| --------------------------------------- | --------------------------------------------------- |
| `GoRoute`                               | `AdaptiveRoute`                                     |
| `StatefulShellRoute.indexedStack`       | `AdaptiveShellRoute` + `AdaptiveBranch`             |
| `context.go(loc)`                       | `router.pushNamedAndRemoveUntil(loc, (_) => false)` |
| `context.push(loc)`                     | `router.pushNamed(loc)`                             |
| `extra`                                 | `arguments`                                         |
| `GoRouterState`                         | `AdaptiveRouteState`                                |
| `pageBuilder`                           | `builder` + optional `transitionsBuilder`           |
| `context.go` / `context.pop` extensions | `AdaptiveRouter.of(context)` only                   |

## Caveats

- Crossing the 840 breakpoint **rebuilds** page `State` (Navigator tree ↔ viewport tree). Keep durable state in the route URL, a signal, or a host store.
- Pane overlays are **clipped**. Dialogs, menus, and sheets inside a column should use the root overlay: `useRootNavigator: AdaptivePaneScope.maybeOf(context) != null`. On compact, a tab-root sheet stays on the nearest navigator and covers the bottom bar only when the shell uses `AdaptiveShellChrome`.
- Context-free `pop` / `maybePop` (including Escape and system back) only handle the top pane and root / shell popups that cover everything. A pane-local sheet / dialog in the **other** pane is not closed by them: use `maybePopFrom(context)` (with a context inside the popup or inside that page), or `Navigator.pop(context)` from inside the popup. Stacked popups close outermost first (root → shell → pane).
- `onExit` runs for `maybePop`, system back, and browser back, after the top page's `PopScope`. At the bottom of the stack, system back asks the route's `onExit` before the app exits. `pop` / `pushReplacementNamed` / `pushNamedAndRemoveUntil` run immediately, like `Navigator`.
- Web keeps hash URLs. The platform's initial route wins over `initialLocation` when it is not `/`.
- One `AdaptiveShellRoute`, top-level only. No nested shells, no `restorable*`, no `context.pushNamed` extensions.

## Package skills

This package ships [agent skills](https://dart.dev/tools/pub/package-skills) under `skills/`. After you depend on it, install them so coding agents use the real APIs:

```bash
dart run skills@ get -p xue_hua_adaptive_sliding_layout --all
```

| Skill | When |
| --- | --- |
| `xue-hua-adaptive-sliding-layout-setup` | `AdaptiveRouter` + `MaterialApp.router` |
| `xue-hua-adaptive-sliding-layout-routing` | Route table, `:param`, `redirect`, `onExit` |
| `xue-hua-adaptive-sliding-layout-navigation` | `pushNamed` / `pop` / `goBranch` |
| `xue-hua-adaptive-sliding-layout-layout` | Panes, breakpoints, breadcrumbs |

## Tests

```bash
flutter analyze && flutter test
cd example && flutter analyze && flutter test
```
