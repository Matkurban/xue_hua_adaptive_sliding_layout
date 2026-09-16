## 3.0.0

### Breaking Changes ⚠️

* Replaced the 2.x host-assembled toolkit (`SlidingShell`, `AdaptiveNavigator`, `AdaptiveNavigatorFallback`, `MultiColumnScaffold`, `SlidingWindowController`, title scraping) with a single declarative router: **`AdaptiveRouter`**.
* Navigation verbs match **`NavigatorState`** names and signatures (`pushNamed`, `pushReplacementNamed`, `pushNamedAndRemoveUntil`, `popAndPushNamed`, `pop`, `maybePop`, `popUntil`, `canPop`). There are no `context.go` / `context.pop` extensions.
* `routeName` is a location string (`/mail/inbox/42`). `arguments` replaces 2.x / go_router `extra`.
* One route table is the source of truth: URL → match list → 1-column `Navigator` or 2-column `SlidingPaneViewport`. `openAfter` / `openSecondary` / `from:` / `handlesRoute` / `buildPage` / fallback are gone.
* `fullscreen: true` routes stack on the root Navigator (login, photo). `AdaptivePaneScope` replaces `inSlidingWindow` + `SlidingPaneScope` + `SlidingPageTitle`.
* No compatibility layer. Migrate hosts to `MaterialApp.router(routerConfig: router)`.

### Features

* go_router-style route tree (`AdaptiveRoute` / `AdaptiveShellRoute` / `AdaptiveBranch`) with `:param` paths, `redirect`, `onExit`, `namedLocation`, and `errorBuilder`.
* Configurable `LayoutBreakpoints` (defaults 600 / 840). Sliding viewport, sash, keep-alive, breadcrumbs, and Escape are kept.
* UI knobs on the viewport / breadcrumbs / shell / overlay: `paneBuilder`, `resizeHandleBuilder`, `slideDuration`, `breadcrumbsBuilder`, `escapePops`, `fullscreenDialog`, `opaque`, `barrierColor`, `barrierDismissible`. Defaults keep the original look. `fullscreenDialog: true` stacks on the root Navigator (covers the shell / bottom bar), matching go_router's `parentNavigatorKey` idiom.
* `AdaptiveRouter` implements `RouterConfig<AdaptiveRouteMatchList>`. `AdaptiveRouteMatch.name` exposes the route table name.
* Example app covers Mail / Contacts / Settings / Playground, plus a DemoFrame width preset for the web demo.

## 2.0.0

### Breaking Changes ⚠️

* **Dependency Migration**: Replaced legacy Flutter package imports with `material_ui` and `cupertino_ui` following the Flutter 3.47 package decoupling.
* **SDK Constraints**: Bumped minimum Flutter SDK requirement to `>=3.44.0`.

### Features & Improvements

* **Example App**: Updated the example application code and import paths to align with the new dependencies.
* **Linter & Analysis**: Added build directory exclusions (`build/**`) in `analysis_options.yaml` to optimize static analysis performance.


## 1.0.0

* Initial extraction of adaptive multi-column sliding layout and AdaptiveNavigator.
