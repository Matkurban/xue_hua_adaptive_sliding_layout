## 3.4.2

### Bug Fixes

- `AdaptiveRouter.refresh()` no longer rebuilds the whole stack from the URL when redirect keeps the current location. Previously every page re-matched with the list-level `arguments`, so intermediate pages (e.g. a chat page under a pushed sub-page) were rebuilt with another page's arguments or `null`. The existing matches (arguments, page keys) are now kept; the stack is only replaced when redirect actually moves elsewhere.
- `pop` now updates the list-level `arguments` to the new top page instead of keeping the popped page's arguments.

## 3.4.1

- update `material_ui` version to ^1.6.0

## 3.4.0

### Breaking Changes ⚠️

- `resizeHandleBuilder` (on `SlidingPaneViewport` and `AdaptiveShellRoute`) is now a `ResizeHandleWidgetBuilder`: `Widget Function(BuildContext context, bool isHovered)`, replacing `WidgetBuilder`. Update custom builders to accept the new `isHovered` flag.
- `SlidingPaneViewport.resizeHandleWidth` is a new required constructor parameter. Hosts that only use `AdaptiveShellRoute` are unaffected — it still defaults `resizeHandleWidth` to `4`.

### Features

- `SlidingPaneViewport` / `AdaptiveShellRoute` gained `resizeHandleWidth` (hit-test width) and `resizeHandleMargin`, sizing and insetting the drag handle independently of its hit area.
- The default resize handle is now a rounded, animated bar that highlights with `colorScheme.primary` on hover or while dragging, instead of a static 2px line. A transparent full-viewport overlay keeps the resize cursor while dragging even if the pointer leaves the handle.
- Default pane split narrowed: `defaultLeftPaneFraction` 0.5 → 0.4, `defaultMinLeftPaneFraction` / `defaultMinRightPaneFraction` 0.3 → 0.35 (same new defaults on `AdaptiveShellRoute`).

### Example

- `AppShell` compact / expanded chrome merged into a single ternary; the expanded rail and body now tint their background with `colorScheme.surfaceContainerHighest`.
- `router_pages.dart` demonstrates a custom `resizeHandleBuilder` and wraps each pane in a `Card`.
- `size_preset_screen.dart` gates the size-preset frame with `LayoutBreakpoints` instead of checking `defaultTargetPlatform`.
- Bumped `cupertino_icons` to `^2.0.0`.

## 3.3.1

### Requirements

- Minimum Dart SDK is `^3.13.0`. Minimum Flutter SDK is `>=3.47.0`.

### Publishing

- Pub.dev topics: `flutter`, `navigation`, `routing`, `layout`, `adaptive-layout`.

## 3.3.0

### Features

- `AdaptiveShellChrome`: on compact, the bottom bar is a child of the branch page route. `bottomNavigationBar` is a `WidgetBuilder` (each page builds its own bar). `showModalBottomSheet` / `showDialog` with `useRootNavigator: false` then covers the bar. `Scaffold.bottomNavigationBar` stays outside that navigator, so a nested sheet cannot cover it. `hidesBottomBarWhenPushed` is unchanged: it only hides the bar when a page is pushed.

### Example

- `AppShell` compact chrome uses `AdaptiveShellChrome`.

### Docs

- READMEs (English and 中文) and package skills show `AdaptiveShellChrome` for the compact bar.

## 3.2.1

### Breaking Changes ⚠️

- `NamedRouteRef` is no longer exported. `RouteRegistry.namedRoutes` is gone. Expand a table name with `AdaptiveRouter.namedLocation`.

### Docs

- Package skills point at the split `lib/src/router` / `lib/src/utils` files. Path helpers (`joinPaths`, `humanizePath`, `PathPattern`) and `NamedRouteRef` are marked internal.

## 3.2.0

### Features

- `popFrom(context)` / `maybePopFrom(context)`: act only on the layer `context` lives in. Inside a dialog / sheet / menu they close that popup; inside a page they close the popup covering that page, or pop the page when it is the uncovered top page; a non-top page is left alone; outside pages they fall back to `pop` / `maybePop`. With one sheet per pane, the context you pass decides which one closes — for example a left-pane sheet that pushed the right page can dismiss itself with `maybePopFrom(context)` instead of popping the new page.

### Fixes

- Stacked popups now close outermost first (root → shell → pane): a root dialog shown above a pane sheet is closed by `maybePop` / Escape before the sheet.
- System back in a two-column layout no longer dismisses an `onExit` confirm dialog: `popRoute` no longer pops a second time after the pane `LocalHistoryEntry`, and `maybePop` still asks `onExit` when that pageless host is not `isCurrent`.

### Docs

- Context-free `pop` / `maybePop` (Escape, system back) only handle the top pane and popups covering the whole shell; a pane-local popup in the other pane needs `maybePopFrom(context)` or `Navigator.pop(context)`.

## 3.1.3

### Fixes

- `pop`, `maybePop`, and `popUntil` close a covering dialog, sheet, or menu before changing the page stack. A pane local-history back entry is not treated as a popup.

## 3.1.2

### Docs

- Ship Dart [package skills](https://dart.dev/tools/pub/package-skills) under `skills/` (`setup`, `routing`, `navigation`, `layout`) with per-API references transcribed from `lib/`.

## 3.1.1

### Fixes

- `goBranch` back to a previously visited `AdaptiveBranch` restores the stored stack (`arguments`, `pageKey`, title signal, completer) instead of rematching the location. `pushNamed(..., arguments:)` data is no longer dropped when switching tabs.

## 3.1.0

### Fixes

- Page `PopScope` is honored on AppBar back, system back, Escape, and `maybePop` (it used to be overridden by `onExit` / skipped by nested Navigators).
- System back no longer exits the app after an `onExit` or exit-dialog "Stay". At the bottom of the stack, the route's `onExit` can still block exit.
- System back right after entering the shell still reaches a shell `PopScope` (the root Navigator's `canHandlePop: false` no longer wins).

### Example

- `AppShell` intercepts system back at a tab root with a confirm dialog (`SystemNavigator.pop()`). Use `showDialog(useRootNavigator: false)` so Stay then back shows the dialog again.

## 3.0.0

### Breaking Changes ⚠️

- Replaced the 2.x host-assembled toolkit (`SlidingShell`, `AdaptiveNavigator`, `AdaptiveNavigatorFallback`, `MultiColumnScaffold`, `SlidingWindowController`, title scraping) with a single declarative router: **`AdaptiveRouter`**.
- Navigation verbs match **`NavigatorState`** names and signatures (`pushNamed`, `pushReplacementNamed`, `pushNamedAndRemoveUntil`, `popAndPushNamed`, `pop`, `maybePop`, `popUntil`, `canPop`). There are no `context.go` / `context.pop` extensions.
- `routeName` is a location string (`/mail/inbox/42`). `arguments` replaces 2.x `extra`.
- One route table is the source of truth: URL → match list → 1-column `Navigator` or 2-column `SlidingPaneViewport`. `openAfter` / `openSecondary` / `from:` / `handlesRoute` / `buildPage` / fallback are gone.
- `fullscreen: true` routes stack on the root Navigator (login, photo). `AdaptivePaneScope` replaces `inSlidingWindow` + `SlidingPaneScope` + `SlidingPageTitle`.
- No compatibility layer. Migrate hosts to `MaterialApp.router(routerConfig: router)`.

### Features

- Declarative route tree (`AdaptiveRoute` / `AdaptiveShellRoute` / `AdaptiveBranch`) with `:param` paths, `redirect`, `onExit`, `namedLocation`, and `errorBuilder`.
- Configurable `LayoutBreakpoints` (defaults 600 / 840). Sliding viewport, sash, keep-alive, breadcrumbs, and Escape are kept.
- UI knobs on the viewport / breadcrumbs / shell / overlay: `paneBuilder`, `resizeHandleBuilder`, `slideDuration`, `breadcrumbsBuilder`, `escapePops`, `fullscreenDialog`, `opaque`, `barrierColor`, `barrierDismissible`. Defaults keep the original look. `fullscreenDialog: true` stacks on the root Navigator (covers the shell / bottom bar).
- `AdaptiveRoute.hidesBottomBarWhenPushed` (default `true`): on compact widths a pushed page covers the host bottom bar, like iOS; medium / expanded are unchanged. Set `false` per route to keep the bar.
- `AdaptiveRouter` implements `RouterConfig<AdaptiveRouteMatchList>`. `AdaptiveRouteMatch.name` exposes the route table name.
- Example app covers Mail / Contacts / Settings / Playground, plus a DemoFrame width preset for the web demo.

## 2.0.0

### Breaking Changes ⚠️

- **Dependency Migration**: Replaced legacy Flutter package imports with `material_ui` and `cupertino_ui` following the Flutter 3.47 package decoupling.
- **SDK Constraints**: Bumped minimum Flutter SDK requirement to `>=3.44.0`.

### Features & Improvements

- **Example App**: Updated the example application code and import paths to align with the new dependencies.
- **Linter & Analysis**: Added build directory exclusions (`build/**`) in `analysis_options.yaml` to optimize static analysis performance.

## 1.0.0

- Initial extraction of adaptive multi-column sliding layout and AdaptiveNavigator.
