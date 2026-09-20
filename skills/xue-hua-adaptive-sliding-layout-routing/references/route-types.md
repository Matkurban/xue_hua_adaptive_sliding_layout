# Route table types

Source: `lib/src/router/route.dart`. UI-knob **behavior** (sash, breadcrumbs, `paneBuilder`) is in the **layout** skill; signatures and defaults are here.

## `AdaptiveRouteBase`

```dart
sealed class AdaptiveRouteBase {
  const AdaptiveRouteBase();
}
```

Closed set: `AdaptiveRoute` | `AdaptiveShellRoute`. Top-level `AdaptiveRouter.routes` is `List<AdaptiveRouteBase>`.

## `AdaptiveRoute`

One page. Child `routes` use relative paths. `:param` syntax matches go_router. First match wins.

### Constructor

```dart
AdaptiveRoute({
  required String path,
  String? name,
  AdaptiveRouteBuilder? builder,
  AdaptiveTitleBuilder? title,
  bool fullscreen = false,
  bool fullscreenDialog = false,
  bool hidesBottomBarWhenPushed = true,
  bool opaque = true,
  Color? barrierColor,
  bool barrierDismissible = false,
  AdaptiveTransitionsBuilder? transitionsBuilder,
  Duration? transitionDuration,
  AdaptiveRedirect? redirect,
  AdaptiveOnExit? onExit,
  List<AdaptiveRoute> routes = const <AdaptiveRoute>[],
})
```

Asserts:

- `builder != null || redirect != null` — `'AdaptiveRoute($path) needs a builder or redirect'`
- `path.isNotEmpty` — `'AdaptiveRoute path must not be empty'`

### `path`

```dart
final String path;
```

This layer’s pattern. Leading `/` ⇒ absolute (`joinPaths` ignores parent). Otherwise appended to the parent full path.

### `name`

```dart
final String? name;
```

Optional stable name for `AdaptiveRouter.namedLocation` / `RouteRegistry.namedLocation`. Must be unique across the whole tree (`ArgumentError('Duplicate route name: …')`). Not a location.

### `builder`

```dart
final AdaptiveRouteBuilder? builder;
```

Builds the page widget. May be null on redirect-only routes (`SizedBox.shrink()` is used if something still asks to build).

### `title`

```dart
final AdaptiveTitleBuilder? title;
```

Evaluated **once** when the registry creates the match. No `BuildContext`. If null, the title is `humanizePath(name ?? matchedLocation)` (see `match.md`).

The `AdaptiveRouteState` passed in has `fullPath` = compiled pattern and `uri` = this layer’s path + query.

To change the title later (async subject, locale): `AdaptivePaneScope.maybeOf(context)?.title.value = …`.

### `fullscreen`

```dart
final bool fullscreen; // default false
```

Root `Navigator` at every width, normal page transition. Same idea as go_router `parentNavigatorKey: rootNavigatorKey`.

### `fullscreenDialog`

```dart
final bool fullscreenDialog; // default false
```

Material fullscreen dialog (`MaterialPage.fullscreenDialog`: slide up, close icon). Also forces the root navigator (`onRootNavigator`).

### `onRootNavigator`

```dart
bool get onRootNavigator => fullscreen || fullscreenDialog;
```

When true, the match is an overlay (`AdaptiveRouteMatch.isOverlay`), `branchIndex` is stored as `null` on the match, and the page is stacked on the root navigator. `hidesBottomBarWhenPushed` is ignored.

### `hidesBottomBarWhenPushed`

```dart
final bool hidesBottomBarWhenPushed; // default true
```

**Compact only** (width `< compactMaxWidth`, usually a bottom bar): this page and every page above it go on the cover navigator, hiding the host chrome. Same name/meaning as iOS `hidesBottomBarWhenPushed`.

`false` keeps the page inside the branch navigator (bar stays). Medium rail and expanded two-pane layout ignore this. Branch **root** pages and `onRootNavigator` pages ignore this.

### Overlay / transition fields

Used only when `transitionsBuilder` is non-null (root navigator `PageRouteBuilder`):

| Field | Default | Meaning |
| --- | --- | --- |
| `opaque` | `true` | `PageRouteBuilder.opaque`. Set `false` for a transparent photo viewer. |
| `barrierColor` | `null` | Barrier color. |
| `barrierDismissible` | `false` | Tap the barrier to pop. |
| `transitionsBuilder` | `null` | Same signature as `PageRouteBuilder.transitionsBuilder`. Ignored for in-pane pages. |
| `transitionDuration` | `null` → 300ms | Duration of that custom route. |

Without `transitionsBuilder`, root pages use a Material page route (`maintainState: true`). 1-column in-shell transitions use `ThemeData.pageTransitionsTheme`.

### `redirect`

```dart
final AdaptiveRedirect? redirect;
```

Runs after the URI matches this route and after the top-level router redirect, before the stack is committed (via `AdaptiveRouter.resolve`).

### `onExit`

```dart
final AdaptiveOnExit? onExit;
```

Return `false` to cancel a **consultative** leave (`maybePop`, system back, browser back / `applyParsed`). Return `true` to allow. Not called by `pop`, `pushReplacementNamed`, or `pushNamedAndRemoveUntil`.

Runs after the page’s `PopScope`. At stack bottom, system back still asks this `onExit` before the app exits.

### `routes`

```dart
final List<AdaptiveRoute> routes;
```

Nested routes, matched in list order, consuming leftover path segments.

## `AdaptiveBranch`

One tab. Paths in `routes` usually start with an absolute `/mail`-style path.

### Constructor

```dart
AdaptiveBranch({
  required List<AdaptiveRoute> routes,
  String? initialLocation,
  AdaptivePlaceholderBuilder? placeholder,
})
```

Asserts `routes.isNotEmpty` (`'AdaptiveBranch.routes must not be empty'`).

`initialLocation` defaults to `_literalPath(routes.first.path)`:

- Ensures a leading `/`.
- If the path contains `:`, throws `ArgumentError('AdaptiveBranch.initialLocation is required when the first path contains parameters: …')`.
- Otherwise normalizes (strip trailing `/` except root).

### Fields

```dart
final List<AdaptiveRoute> routes;
final String initialLocation;
final AdaptivePlaceholderBuilder? placeholder;
```

`placeholder` is the empty **right** pane when this branch’s depth is 1 in two-column mode. Wins over `AdaptiveShellRoute.placeholder`.

`AdaptiveShellState.goBranch(index, initialLocation: true)` and first visit without a stored stack navigate to `initialLocation`.

## `AdaptiveShellRoute`

Multi-branch chrome. Width picks 1-column `Navigator` vs 2-column `SlidingPaneViewport`.

`ponytail:` only one of these in the tree, top-level. Nested shells are not supported.

### Constructor

```dart
AdaptiveShellRoute({
  required AdaptiveShellBuilder builder,
  required List<AdaptiveBranch> branches,
  LayoutBreakpoints breakpoints = const LayoutBreakpoints(),
  bool showBreadcrumbs = true,
  bool resizable = true,
  double initialLeftPaneFraction = 0.5,
  double minLeftPaneFraction = 0.3,
  double minRightPaneFraction = 0.3,
  ValueChanged<double>? onLeftPaneFractionChanged,
  AdaptiveBreadcrumbsBuilder? breadcrumbsBuilder,
  AdaptivePlaceholderBuilder? placeholder,
  SlidingPaneFrameBuilder? paneBuilder,
  WidgetBuilder? resizeHandleBuilder,
  Duration slideDuration = SlidingPaneViewport.defaultSlideDuration, // 280ms
  Curve slideCurve = SlidingPaneViewport.defaultSlideCurve,         // easeOutCubic
  bool escapePops = true,
})
```

Asserts `branches.isNotEmpty`.

### `builder`

```dart
final AdaptiveShellBuilder builder;
```

Host chrome (rail / bottom bar). **Must** place `child` in the content area. `child` is the current branch’s navigator or viewport (plus an `IndexedStack` of branches).

### `branches`

```dart
final List<AdaptiveBranch> branches;
```

Index `i` is `AdaptiveShellState.currentIndex` / `AdaptiveRouter.currentBranch`.

### `breakpoints`

```dart
final LayoutBreakpoints breakpoints;
```

Default `compactMaxWidth: 600`, `expandedMinWidth: 840`. See the **layout** skill.

### UI knobs (signatures)

| Field | Default | Role |
| --- | --- | --- |
| `showBreadcrumbs` | `true` | Draw the strip above the viewport when expanded. |
| `resizable` | `true` | Show the sash when two columns are visible. |
| `initialLeftPaneFraction` | `0.5` | Seeds `AdaptiveRouter.leftPaneFraction`. |
| `minLeftPaneFraction` | `0.3` | Sash clamp lower bound. |
| `minRightPaneFraction` | `0.3` | Sash clamp; left max is `1 - this`. |
| `onLeftPaneFractionChanged` | `null` | Called on sash pointer-up **after** the router signal is written. |
| `breadcrumbsBuilder` | `null` | Replace `AdaptiveBreadcrumbs`. Still gated by `showBreadcrumbs`. |
| `placeholder` | `null` | Default empty right pane; `AdaptiveBranch.placeholder` wins. |
| `paneBuilder` | `null` | Wrap each column; `index == panes.length` is the empty right slot. Default: card in 2-col, flat in 1-col. |
| `resizeHandleBuilder` | `null` | Visual only; 44px hit target stays. |
| `slideDuration` | 280ms | Column slide. |
| `slideCurve` | `Curves.easeOutCubic` | Column slide. |
| `escapePops` | `true` | Escape calls `AdaptiveRouter.maybePop` unless focus is an `EditableTextState`. |
