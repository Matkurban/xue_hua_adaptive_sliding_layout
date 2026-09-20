# AdaptiveRouter wiring

Source: `lib/src/router/adaptive_router.dart`.

## `AdaptiveRouter`

`AdaptiveRouter` implements `RouterConfig<AdaptiveRouteMatchList>`. Give the instance to `MaterialApp.router(routerConfig: router)`. Navigation verbs (`pushNamed`, `pop`, `goBranch`, `namedLocation`, …) are documented in the **navigation** skill.

The constructor calls `WidgetsFlutterBinding.ensureInitialized()`.

## Constructor

```dart
AdaptiveRouter({
  required List<AdaptiveRouteBase> routes,
  String initialLocation = '/',
  AdaptiveRedirect? redirect,
  AdaptiveRouteBuilder? errorBuilder,
  GlobalKey<NavigatorState>? navigatorKey,
  List<NavigatorObserver> observers = const <NavigatorObserver>[],
  int redirectLimit = 5,
})
```

| Parameter         | Meaning                                                                                                                                                                                                                                   |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `routes`          | Top-level route table. At most one `AdaptiveShellRoute`, and it must be top-level. Compiled into `registry` (`RouteRegistry`). Duplicate `AdaptiveRoute.name` values throw `ArgumentError`. A second or nested shell throws `StateError`. |
| `initialLocation` | Used when the platform does not supply a URL. See **Effective initial location**.                                                                                                                                                         |
| `redirect`        | Top-level redirect. Return a new location string or `null`. Runs before per-route `AdaptiveRoute.redirect`.                                                                                                                               |
| `errorBuilder`    | Page for no match or a redirect loop. Receives an `AdaptiveRouteState` whose `error` is set.                                                                                                                                              |
| `navigatorKey`    | Root `Navigator` key. Created if omitted. Needed for `refresh` / `resolve` (they read `navigatorKey.currentContext`) and for Overlay lookup.                                                                                              |
| `observers`       | Root `Navigator` observers.                                                                                                                                                                                                               |
| `redirectLimit`   | Max redirect hops. Exceeding it yields `Exception('Redirect loop after $redirectLimit hops')` and `errorBuilder`.                                                                                                                         |

Also constructed (not parameters):

- `registry = RouteRegistry(routes)`
- empty `_current` with `uri: Uri.parse(effectiveInitial)`
- `location = signal(effectiveInitial)`
- `matches = signal(_current)`
- `currentBranch = signal(0)`
- `leftPaneFraction = signal(shell?.initialLeftPaneFraction ?? 0.5)`
- `PlatformRouteInformationProvider` with that URI
- `_AdaptiveRouteInformationParser`, `_AdaptiveRouterDelegate`, `RootBackButtonDispatcher`

### Effective initial location

```
platform = WidgetsBinding.instance.platformDispatcher.defaultRouteName
if (platform.isNotEmpty && platform != '/') use platform
else use initialLocation
```

## Fields

### `redirect`

```dart
final AdaptiveRedirect? redirect;
```

`typedef AdaptiveRedirect = FutureOr<String?> Function(BuildContext context, AdaptiveRouteState state)`.

Return a location to replace the current URI; `null` keeps it. Compared with `uri.path` + `uri.query` (a leading `/` is added to the returned string if missing).

### `errorBuilder`

```dart
final AdaptiveRouteBuilder? errorBuilder;
```

Used when `matches` is empty and `error != null`, or when the delegate built no pages. If null, those cases render nothing extra.

### `navigatorKey`

```dart
final GlobalKey<NavigatorState> navigatorKey;
```

Root navigator. `refresh()` and imperative `*Named` redirects no-op / skip redirect when `currentContext` is null.

### `observers`

```dart
final List<NavigatorObserver> observers;
```

Attached to the root `Navigator` only.

### `redirectLimit`

```dart
final int redirectLimit;
```

Default `5`. Counts hops in `resolve`.

### `registry`

```dart
final RouteRegistry registry;
```

Compiled table. Public API of `RouteRegistry` is in the **routing** skill (`references/match.md`).

## RouterConfig

```dart
late final RouteInformationProvider routeInformationProvider;
late final RouteInformationParser<AdaptiveRouteMatchList> routeInformationParser;
late final RouterDelegate<AdaptiveRouteMatchList> routerDelegate;
late final BackButtonDispatcher backButtonDispatcher;
```

Assigned in the constructor. `routeInformationParser.parseRouteInformationWithDependencies` calls `resolve`. `restoreRouteInformation` writes `configuration.uri`. `backButtonDispatcher` is `RootBackButtonDispatcher()`.

## Signals

Subscribe with `SignalBuilder`.

### `location`

```dart
late final Signal<String> location;
```

Current location as `path` or `path?query` (no scheme/host). Empty path becomes `'/'`. Updated in `_setCurrent`.

### `matches`

```dart
late final Signal<AdaptiveRouteMatchList> matches;
```

Full match list (branch pages + root overlays). Same object written in `_setCurrent`.

### `currentBranch`

```dart
late final Signal<int> currentBranch;
```

Starts at `0`. Updated only when the new list has a non-null `branchIndex`.

### `leftPaneFraction`

```dart
late final Signal<double> leftPaneFraction;
```

Shared sash fraction across tabs. Initial value is `shell?.initialLeftPaneFraction ?? 0.5`. The viewport writes it on sash pointer-up via `AdaptiveShellRoute.onLeftPaneFractionChanged` when the host wires that (the built-in shell writes this signal).

## `shell`

```dart
AdaptiveShellRoute? get shell => registry.shell;
```

The unique top-level shell, or `null` if the table has none.

## `of` / `maybeOf`

```dart
static AdaptiveRouter of(BuildContext context)
static AdaptiveRouter? maybeOf(BuildContext context)
```

`maybeOf` reads `AdaptiveRouterScope` via `dependOnInheritedWidgetOfExactType` (rebuilds when the scope notifies). `of` asserts `'AdaptiveRouter not found in context'` when null.

The scope is inserted by the router delegate around the navigator. Pages under `MaterialApp.router(routerConfig: router)` can call `of`.

## `refresh`

```dart
void refresh()
```

Re-runs `resolve(context, _current.uri, arguments: _current.arguments)` and `_setCurrent`. Returns immediately if `navigatorKey.currentContext` is null. The `then` is not awaited.

Call after sign-in / sign-out or any other value that `redirect` closures close over.

## `resolve`

```dart
Future<AdaptiveRouteMatchList> resolve(
  BuildContext context,
  Uri uri, {
  Object? arguments,
})
```

Used by the route-information parser and by `refresh` / imperative redirects.

For up to `redirectLimit` hops:

1. If `!context.mounted`, return `registry.match(current, arguments: arguments)` without further redirects.
2. `matched = registry.match(current, arguments: arguments)`.
3. Call **top-level** `redirect(context, state)` where `state` comes from the last match, or a synthetic state when the list is empty (`pageKey: ValueKey('adaptive-empty')`).
4. If that returns a location whose path+query differs, parse it (add `/` if needed) and continue.
5. Else walk `matched.matches` in order and call each `AdaptiveRoute.redirect`. The first location whose path+query differs restarts the hop.
6. If nothing redirected, return `matched`.

After `redirectLimit` hops, return an empty list with

```dart
error: Exception('Redirect loop after $redirectLimit hops')
```

and `uri` equal to the last hop.

## `stackForBranch`

```dart
List<AdaptiveRouteMatch> stackForBranch(int index)
```

- If `_current.branchIndex == index`, return `_current.branchMatches`.
- Else if that branch has a stored non-empty stack, return it (same match instances; titles / `arguments` / `pageKey` preserved — 3.1.1).
- Else if there is a shell and `index` is in range, `registry.match(Uri.parse(branch.initialLocation)).branchMatches`.
- Else `const <AdaptiveRouteMatch>[]`.

Used by the built-in shell to keep an `IndexedStack` of tabs.

## `buildMatch`

```dart
Widget buildMatch(BuildContext context, AdaptiveRouteMatch match)
```

Calls `match.route.builder(context, state)` (`SizedBox.shrink()` if `builder` is null), wraps it in `AdaptiveRouteScope` + an internal page host that registers the `ModalRoute` for `maybePop` / `PopScope`. `state` is `match.toState(_current.uri, error: _current.error)`.

Host apps rarely call this; the shell and `pageFor` do.

## `pageFor`

```dart
Page<dynamic> pageFor(BuildContext context, AdaptiveRouteMatch match)
```

Builds the internal `Page` used on the root / 1-column `Navigator`. `Page.key` is `match.pageKey`, `name` is `match.matchedLocation`, `arguments` is `match.arguments`. The route created from the page honors `fullscreenDialog`, and if `transitionsBuilder` is set, also `opaque`, `barrierColor`, `barrierDismissible`, `transitionDuration` (default 300ms).

## `handleRemovedPage`

```dart
void handleRemovedPage(Page<dynamic> page)
```

`handleRemovedPageKey(page.key, null)`.

## `handleRemovedPageKey`

```dart
void handleRemovedPageKey(LocalKey? key, Object? result)
```

No-op if `key` is null or is not the current stack top `pageKey`. Otherwise pops that top (completes its completer with `result`). Prevents a double-pop when Flutter already removed the page.

Wired as `Navigator.onDidRemovePage`.

## `applyParsed`

```dart
Future<void> applyParsed(AdaptiveRouteMatchList configuration)
```

Called when the parser delivers a new configuration (browser URL, deep link).

- If already ready and path+query equal `_current.uri`, return.
- If ready, collect matches in `_current` (reversed) whose `pageKey` is absent from `configuration`. For each, run `onExit`. If any returns `false`, notify the delegate and keep the old stack (browser back is cancelled).
- Otherwise `_setCurrent(configuration)`.

`onExit` is **not** used by `pop` / `pushReplacementNamed` / `pushNamedAndRemoveUntil`. It **is** used here (URL / system back) and by `maybePop`.
