# Match objects and RouteRegistry

`AdaptiveRoutePredicate` is documented in the **navigation** skill.

## `AdaptiveRouteMatch`

Source: `lib/src/router/adaptive_route_match.dart`.

One page / pane in the stack.

### Constructor

```dart
AdaptiveRouteMatch({
  required AdaptiveRoute route,
  required String matchedLocation,
  required String fullPath,
  required Map<String, String> pathParameters,
  required Map<String, String> queryParameters,
  required LocalKey pageKey,
  required Signal<String> title,
  Object? arguments,
  Completer<Object?>? completer,
  bool isImperative = false,
  int? branchIndex,
})
```

### Fields

| Field             | Meaning                                                                                                                                                                        |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `route`           | The table entry that matched.                                                                                                                                                  |
| `matchedLocation` | Concrete path for this layer, e.g. `/mail/inbox/42`.                                                                                                                           |
| `fullPath`        | Pattern, e.g. `/mail/:folder/:threadId`.                                                                                                                                       |
| `pathParameters`  | Params accumulated from the root through this layer.                                                                                                                           |
| `queryParameters` | Query of the navigation URI (same map on every match of that navigation).                                                                                                      |
| `arguments`       | `pushNamed(..., arguments:)`.                                                                                                                                                  |
| `pageKey`         | Keep-alive key. URL-derived: `ValueKey(matchedLocation)`. Imperative push: `ValueKey('imp:$id:$matchedLocation')`.                                                             |
| `title`           | Breadcrumb signal. Pages may write `AdaptivePaneScope.maybeOf(context)?.title.value`.                                                                                          |
| `completer`       | Completes the `Future` returned by `pushNamed` / other `*Named` verbs when this page is disposed / popped. `null` on URL-derived matches (those futures complete with `null`). |
| `isImperative`    | `true` when this leaf was appended by `pushNamed` rather than being a URL prefix fill.                                                                                         |
| `branchIndex`     | `AdaptiveBranch` index. `null` for off-shell / `onRootNavigator` matches.                                                                                                      |

### `name`

```dart
String? get name => route.name;
```

### `isOverlay`

```dart
bool get isOverlay => route.onRootNavigator || branchIndex == null;
```

Overlays sit on the root `Navigator` after `branchMatches`.

### `toState`

```dart
AdaptiveRouteState toState(Uri uri, {Exception? error})
```

`uri` is the **router** location (may be an overlay URI). Copies `matchedLocation`, `fullPath`, `route.name`, params, query, `arguments`, `pageKey`, and the optional list-level `error`.

### `uri`

```dart
Uri get uri
```

This match’s location: `path: matchedLocation`, query if `queryParameters` is not empty.

### `copyWith`

```dart
AdaptiveRouteMatch copyWith({
  LocalKey? pageKey,
  Completer<Object?>? completer,
  bool? isImperative,
  Object? arguments,
  Map<String, String>? queryParameters,
  Signal<String>? title,
})
```

Copies `route`, `matchedLocation`, `fullPath`, `pathParameters`, `branchIndex`. Does **not** dispose the old `title`. Host apps rarely call this; the navigation engine does when marking a leaf imperative.

### `dispose`

```dart
void dispose([Object? result])
```

If `completer` exists and is not completed, `complete(result)`. Then, once, `title.dispose()`. A second call is a no-op for the signal.

## `AdaptiveRouteMatchList`

Source: `lib/src/router/adaptive_route_match_list.dart`.

One navigation result: current branch stack + root overlays.

### Constructor

```dart
AdaptiveRouteMatchList({
  required List<AdaptiveRouteMatch> matches,
  required Uri uri,
  AdaptiveShellRoute? shell,
  int? branchIndex,
  Object? arguments,
  Exception? error,
})
```

`matches` is root-to-top: branch pages first, overlays after.

### `notFound`

```dart
factory AdaptiveRouteMatchList.notFound(Uri uri, {Object? arguments})
```

Empty `matches`, `error: Exception('No routes for ${uri.path}')`.

### Fields

```dart
final List<AdaptiveRouteMatch> matches;
final Uri uri;                       // written to the browser
final AdaptiveShellRoute? shell;     // null for a pure overlay deep link (e.g. /login)
final int? branchIndex;
final Object? arguments;
final Exception? error;
```

### `branchMatches`

```dart
List<AdaptiveRouteMatch> get branchMatches
```

`matches` where `!isOverlay`.

### `overlayMatches`

```dart
List<AdaptiveRouteMatch> get overlayMatches
```

`matches` where `isOverlay`.

### `last`

```dart
AdaptiveRouteMatch? get last => matches.isEmpty ? null : matches.last;
```

### `canPop`

```dart
bool get canPop
```

`true` when:

- more than one overlay, or
- exactly one overlay **and** the branch is non-empty, or
- branch depth > 1.

A single branch-root page with no overlay is not poppable. Overlay-only stacks of length 1 are not poppable.

### `copyWith`

```dart
AdaptiveRouteMatchList copyWith({
  List<AdaptiveRouteMatch>? matches,
  Uri? uri,
  AdaptiveShellRoute? shell,
  int? branchIndex,
  Object? arguments,
  Exception? error,
  bool clearError = false,
})
```

`clearError: true` sets `error` to `null`. Otherwise `error ?? this.error`.

## `NamedRouteRef`

Source: `lib/src/router/named_route_ref.dart`. Internal (not exported). Used only by `RouteRegistry`.

Compiled named route.

```dart
const NamedRouteRef({
  required AdaptiveRoute route,
  required String fullPath,
  required PathPattern pattern,
  int? branchIndex,
})
```

| Field         | Meaning                                   |
| ------------- | ----------------------------------------- |
| `route`       | Table entry.                              |
| `fullPath`    | Joined pattern, e.g. `/mail/:folder/:id`. |
| `pattern`     | Used by `expand` / `namedLocation`.       |
| `branchIndex` | Branch, or `null` if off-shell.           |

## `RouteRegistry`

Source: `lib/src/router/route_registry.dart`.

Walks the tree once: registers names, finds the unique shell, matches URIs.

### Constructor

```dart
RouteRegistry(List<AdaptiveRouteBase> routes)
```

Depth-first walk:

- `AdaptiveShellRoute`: throws `StateError('ponytail: only one AdaptiveShellRoute is supported; …')` if a shell already exists; throws `StateError('ponytail: AdaptiveShellRoute must be a top-level route.')` if `parentFullPath` is non-empty and not `/`. Then walks each branch’s `routes` with `branchIndex: i` and empty parent path.
- `AdaptiveRoute`: `fullPath = joinPaths(parent, path)`. If `name != null` and already registered, `ArgumentError('Duplicate route name: …')`. Then walks `routes` with that `fullPath`.

### Fields

```dart
final List<AdaptiveRouteBase> routes;
AdaptiveShellRoute? get shell;
```

### `namedLocation`

```dart
String namedLocation(
  String name, {
  Map<String, String> pathParameters = const <String, String>{},
  Map<String, dynamic> queryParameters = const <String, dynamic>{},
})
```

Unknown `name` → `ArgumentError('Unknown route name: $name')`. Missing path param → `ArgumentError` from `PathPattern.expand`. Query values are `toString()` then encoded via `Uri(path:, queryParameters:)`. Empty query returns the path only.

`AdaptiveRouter.namedLocation` forwards here.

### `match`

```dart
AdaptiveRouteMatchList match(Uri uri, {Object? arguments})
```

Tries top-level nodes in declaration order against `uri.pathSegments`. Failure → `notFound`.

Matching rules:

- Shell: try each branch in order; first hit wins.
- Route: `PathPattern(route.path).match` from the current start index. Merge params. Build an `AdaptiveRouteMatch` with `pageKey: ValueKey(matchedLocation)`, `title` from `AdaptiveRoute.title` or `humanizePath`, `branchIndex: null` if `onRootNavigator`.
- If all segments are consumed, return the prefix including this match.
- If leftover segments exist and `routes` is empty, dispose this match and fail this node.
- Else recurse into `routes`. On failure, dispose this match.

`matchedLocation` is `'/' + pathSegments.take(consumed).join('/')`, or `'/'` when consumed is 0.

## Internal helpers

Not exported. `humanizePath` / `isMatchPrefix` / `reusePrefixMatches` live in `lib/src/utils/match_utils.dart`. The engine uses them from `route_registry.dart` / `navigation.dart`.

## `humanizePath`

```dart
String humanizePath(String name)
```

Default title when `AdaptiveRoute.title` is null.

- If `name` starts with `/`, take the last non-empty segment that does not start with `:`, then humanize it. Empty remainder falls through.
- Else strip a trailing `Page` or `View` and humanize if that changed the string.
- Else humanize `name`.

Humanize: insert a space before each `aA` camel-case boundary; uppercase the first character.

## `isMatchPrefix`

```dart
bool isMatchPrefix(
  List<AdaptiveRouteMatch> current,
  List<AdaptiveRouteMatch> target,
)
```

`true` when `current.length <= target.length` and each `current[i].matchedLocation == target[i].matchedLocation` (equal lists count as prefix). Used by `pushNamed` to decide “extend the stack” vs “append the leaf”.

## `reusePrefixMatches`

```dart
List<AdaptiveRouteMatch> reusePrefixMatches(
  List<AdaptiveRouteMatch> current,
  List<AdaptiveRouteMatch> target,
)
```

For each index in `target`, keep `current[i]` when locations match (and `dispose` the unused `target[i]`); otherwise keep `target[i]`. Prevents title-signal leaks on prefix reuse.

## Dropped-match dispose

Lives in `AdaptiveRouter._setCurrent` (`lib/src/router/adaptive_router.dart`). `dispose()` every match in the old list whose `pageKey` is absent from the new list **and** from stored branch stacks. Does not pass a result.
