# AdaptiveRouter navigation verbs

Source: `lib/src/router/adaptive_router.dart` (public methods) and the internal engine in `lib/src/router/navigation.dart` (not exported — do not import it).

Constructor, signals, `of` / `refresh` / `resolve` are in the **setup** skill.

A location string that does not start with `/` is parsed as `'/$routeName'`.

## `namedLocation`

```dart
String namedLocation(
  String name, {
  Map<String, String> pathParameters = const <String, String>{},
  Map<String, dynamic> queryParameters = const <String, dynamic>{},
})
```

Forwards to `registry.namedLocation`. Expand `AdaptiveRoute.name` into a location, then pass that string to a `*Named` verb.

- Unknown `name` → `ArgumentError('Unknown route name: $name')`.
- Missing path param → `ArgumentError('Missing path parameter :$name')`.
- Query values are `toString()`’d and URI-encoded. Empty query returns the path only.

## `pushNamed`

```dart
Future<T?> pushNamed<T extends Object?>(
  String routeName, {
  Object? arguments,
})
```

Runs redirect (`resolve`) then the engine `pushNamed`. Returns a future that completes when the **new top** match’s `completer` completes (`pop` / dispose). If that match has no completer (URL-derived, no new leaf), the future completes with `null`.

Does **not** call `onExit`.

### Engine rules (after a successful match)

If `target.error != null`, the error list is installed as the new current (404 / `errorBuilder`).

**Overlay** when `matches` is empty, any match has `route.onRootNavigator`, or `branchIndex == null`:

- Empty or errored current stack → use `target`.
- Else dispose `target`’s non-leaf matches, mark the leaf imperative (`new pageKey`, `Completer`, `isImperative: true`), append it to `current.matches`.

**Cross-branch** (`current.shell != null`, both sides have a `branchIndex`, they differ): dispose current overlays; install `target` (URL-derived stack for that tab).

**Same branch**: dispose current overlays, then

- Prefix (`isMatchPrefix(currentBranch, nextBranch)`): `reusePrefixMatches`. If the reused stack is longer and the new last has no completer, copy it with a new `Completer` so `pushNamed` can be awaited.
- Not a prefix: dispose `nextBranch`’s non-leaf matches; append the imperative leaf onto `currentBranch`.

## `pushReplacementNamed`

```dart
Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
  String routeName, {
  TO? result,
  Object? arguments,
})
```

Redirect, then `_removeTop(current, result)` (completes the old top’s completer with `result`), then `pushNamed` on that base. Does not call `onExit`. Overlay tops are removed before branch tops.

Same-level swap: the right pane updates in place when the replacement is a sibling path.

## `pushNamedAndRemoveUntil`

```dart
Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
  String routeName,
  AdaptiveRoutePredicate predicate, {
  Object? arguments,
})
```

Redirect, `popUntil` until `predicate` is true or `canPop` is false, then `pushNamed`. Does not call `onExit`.

`predicate: (_) => false` pops to the branch root (or overlay-only root) and then pushes — go_router `context.go` / deep link / login return / reset tab.

## `popAndPushNamed`

```dart
Future<T?> popAndPushNamed<T extends Object?, TO extends Object?>(
  String routeName, {
  TO? result,
  Object? arguments,
})
```

Redirect, then `pop` if `canPop` (passing `result`), else keep current; then `pushNamed`. Does not call `onExit`.

## `pop`

```dart
void pop<T extends Object?>([T? result])
```

No-op if `!canPop`. Otherwise removes the top overlay or the top branch page, completes that match’s completer with `result`, writes the previous match’s `uri` as the location.

Does **not** ask `PopScope` or `onExit`.

## `maybePop`

```dart
Future<bool> maybePop<T extends Object?>([T? result])
```

Consultative pop. Used by AppBar back, system back (via `popRoute`), browser back, and Escape (`escapePops`).

1. If `!canPop`, return `false` (no exit dialog).
2. If the top page’s hosted `ModalRoute` is not current, return `false`.
3. Read `popDisposition` **without** the route’s `onExit` override (`scopeDisposition` on the package’s page route). If `doNotPop` (page `PopScope`), call `onPopInvokedWithResult(false, result)` and return `false`.
4. Else call `onExit` if present. If it returns `false`, or the top match changed while awaiting, return `false`.
5. Else pop with `result` and return `true`.

If `onExit` is null, step 4 allows the pop.

At stack bottom, **system** back (`RouterDelegate.popRoute`) may still ask the bottom route’s `onExit` before the app exits. `maybePop` itself does not.

## `popUntil`

```dart
void popUntil(AdaptiveRoutePredicate predicate)
```

Repeated `pop` while `canPop && (last == null || !predicate(last))`. Does not call `onExit`. Does not pop the branch root.

## `canPop`

```dart
bool canPop() => _current.canPop;
```

True when there is an overlay above a branch (or more than one overlay), or branch depth > 1. See `AdaptiveRouteMatchList.canPop` in the routing skill.

## `goBranch`

```dart
void goBranch(int index, {bool initialLocation = false})
```

No-op if there is no shell, or `index` is out of range.

- `initialLocation: false` (default) and this branch has a stored non-empty stack: restore those **same** `AdaptiveRouteMatch` instances (3.1.1: `arguments`, `pageKey`, title signal, completer survive). Location becomes the stored branch location (last branch match’s uri, or the list uri). Current overlays are disposed.
- Otherwise navigate to `branch.initialLocation` when `initialLocation: true`, else `_branchLocations[index] ?? branch.initialLocation`, via `registry.match`. Current overlays are disposed.

`AdaptiveShellState.goBranch` is this same tear-off (`goBranch: _router.goBranch`).

Switching away from a branch stores its `branchMatches` and location so a later `goBranch` can restore them.

## Completers and `_wait`

```dart
Future<T?> _wait<T>(AdaptiveRouteMatchList next)
```

(`_wait` is private; described so the `*Named` futures are not mysterious.)

Uses `next.last?.completer`. Null completer → `Future<T?>.value(null)`. Else `completer.future` cast to `T?`.

Imperative leaves get a completer. Prefix-extended new last pages get one if they lacked it. URL-derived tab switches and `notFound` lists typically have none.
