# Route and shell state

`AdaptiveShellState` / `AdaptiveShellScope` (chrome width, `goBranch`) live in the **layout** skill (`references/shell-state.md`). This file is the **page** snapshot.

## `AdaptiveRouteState`

Source: `lib/src/router/adaptive_route_state.dart`.

Snapshot of the matched route. Second argument of `AdaptiveRoute.builder`. Also readable via `AdaptiveRouteState.of(context)` inside that page.

Fields align with `RouteSettings`: `arguments` is `pushNamed(..., arguments:)`; `name` is the optional table name, **not** the location.

### Constructor

```dart
const AdaptiveRouteState({
  required Uri uri,
  required String matchedLocation,
  required String fullPath,
  required LocalKey pageKey,
  String? name,
  Map<String, String> pathParameters = const <String, String>{},
  Map<String, String> queryParameters = const <String, String>{},
  Object? arguments,
  Exception? error,
})
```

### Fields

| Field             | Meaning                                                                                                                                                        |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `uri`             | Current router / browser location, including query.                                                                                                            |
| `matchedLocation` | This layer’s matched path, e.g. `/mail/inbox/42` (no query).                                                                                                   |
| `fullPath`        | Compiled pattern, e.g. `/mail/:folder/:threadId`.                                                                                                              |
| `name`            | `AdaptiveRoute.name`, or `null`.                                                                                                                               |
| `pathParameters`  | Accumulated path params, e.g. `{'threadId': '42'}`.                                                                                                            |
| `queryParameters` | URI query; values are already `String`.                                                                                                                        |
| `arguments`       | Opaque object from `pushNamed(..., arguments:)`.                                                                                                               |
| `error`           | Set on no-match or redirect-loop states; `null` on normal navigation.                                                                                          |
| `pageKey`         | Key of this page in the `Navigator` / pane. URL-derived matches use `ValueKey(matchedLocation)`; imperative pushes use `ValueKey('imp:$id:$matchedLocation')`. |

### `of` / `maybeOf`

```dart
static AdaptiveRouteState of(BuildContext context)
static AdaptiveRouteState? maybeOf(BuildContext context)
```

Both read `AdaptiveRouteScope`. `of` asserts `'AdaptiveRouteState not found in context'`. `maybeOf` is null outside a routed page (shell chrome, a dialog that is not a route page).

## `AdaptiveRouteScope`

Source: `lib/src/router/adaptive_route_scope.dart`.

`InheritedWidget` that publishes `AdaptiveRouteState`. Created by `AdaptiveRouter.buildMatch`.

### Constructor

```dart
const AdaptiveRouteScope({
  super.key,
  required AdaptiveRouteState state,
  required super.child,
})
```

### Fields

```dart
final AdaptiveRouteState state;
```

### `maybeOf`

```dart
static AdaptiveRouteState? maybeOf(BuildContext context)
```

`dependOnInheritedWidgetOfExactType<AdaptiveRouteScope>()?.state`.

### `updateShouldNotify`

```dart
@override
bool updateShouldNotify(AdaptiveRouteScope oldWidget) =>
    state.uri != oldWidget.state.uri ||
    state.matchedLocation != oldWidget.state.matchedLocation ||
    state.arguments != oldWidget.state.arguments ||
    state.error != oldWidget.state.error;
```

Dependents rebuild when those four change. `pathParameters` / `queryParameters` ride on `uri` / `matchedLocation`.
