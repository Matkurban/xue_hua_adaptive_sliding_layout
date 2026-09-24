# Route typedefs

## `AdaptiveRouteBuilder`

Source: `lib/src/router/adaptive_route.dart`.

```dart
typedef AdaptiveRouteBuilder =
    Widget Function(BuildContext context, AdaptiveRouteState state);
```

Page factory. Second argument is the match snapshot (`AdaptiveRoute.builder`, `AdaptiveRouter.errorBuilder`).

## `AdaptiveShellBuilder`

Source: `lib/src/router/adaptive_shell_route.dart`.

```dart
typedef AdaptiveShellBuilder = Widget Function(
  BuildContext context,
  AdaptiveShellState shell,
  Widget child,
);
```

Shell chrome factory. `child` is the current branch content (must be placed in the body). `shell` carries `currentIndex`, width bands, `leftPaneFraction`, and `goBranch`.

## `AdaptivePlaceholderBuilder`

Source: `lib/src/router/adaptive_branch.dart`.

```dart
typedef AdaptivePlaceholderBuilder = Widget Function(BuildContext context);
```

Empty **right** pane when two columns are showing and the branch depth is less than 2. Set on `AdaptiveShellRoute.placeholder` or `AdaptiveBranch.placeholder` (branch wins).

## `AdaptiveRedirect`

Source: `lib/src/router/adaptive_route.dart`.

```dart
typedef AdaptiveRedirect =
    FutureOr<String?> Function(BuildContext context, AdaptiveRouteState state);
```

Return a location string to send the router there; `null` keeps the current URI. Used as `AdaptiveRouter.redirect` and `AdaptiveRoute.redirect`. Sync or async.

A returned value is parsed with a leading `/` added if missing. A hop happens only when path+query differ from the current URI.

## `AdaptiveOnExit`

Source: `lib/src/router/adaptive_route.dart`.

```dart
typedef AdaptiveOnExit =
    FutureOr<bool> Function(BuildContext context, AdaptiveRouteState state);
```

Return `false` to cancel a consultative leave (`AdaptiveRouter.maybePop`, system / browser back, `applyParsed`). Return `true` to pop. Sync or async.

Not invoked by `pop`, `pushReplacementNamed`, or `pushNamedAndRemoveUntil`.

## `AdaptiveTitleBuilder`

Source: `lib/src/router/adaptive_route.dart`.

```dart
typedef AdaptiveTitleBuilder = String Function(AdaptiveRouteState state);
```

Breadcrumb / pane title at match time. **No `BuildContext`.**

For gen-l10n use `lookupAppLocalizations(locale)` with `WidgetsBinding.instance.platformDispatcher.locale` (or your locale signal), or `Intl.defaultLocale`. For a context or a live locale switch, write `AdaptivePaneScope.maybeOf(context)?.title.value` from the page.

## `AdaptiveTransitionsBuilder`

Source: `lib/src/router/adaptive_route.dart`.

```dart
typedef AdaptiveTransitionsBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
);
```

Same signature as `PageRouteBuilder.transitionsBuilder`. Applied only on root-navigator pages that set `AdaptiveRoute.transitionsBuilder`. In-pane pages ignore it.
