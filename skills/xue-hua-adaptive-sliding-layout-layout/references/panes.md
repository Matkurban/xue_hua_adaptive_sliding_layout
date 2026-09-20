# SlidingPane, AdaptivePaneScope, SlidingPaneFrameBuilder

Source: `lib/src/layout/pane_scope.dart`.

## `SlidingPaneFrameBuilder`

```dart
typedef SlidingPaneFrameBuilder =
    Widget Function(BuildContext context, int index, Widget child);
```

Wraps each column. `index` is the stack index (0 = branch root). When `index == panes.length`, `child` is the empty **right** placeholder slot.

Set on `SlidingPaneViewport.paneBuilder` / `AdaptiveShellRoute.paneBuilder`. If null: 2-column uses a card shell; 1-column is flat (optional left divider).

## `SlidingPane`

One column in `SlidingPaneViewport`.

### Constructor

```dart
const SlidingPane({
  required LocalKey key,
  required Signal<String> title,
  required Widget child,
})
```

`key` must stay stable across depth changes so the in-pane `State` is not recreated. The built-in shell uses `AdaptiveRouteMatch.pageKey`.

### Fields

```dart
final LocalKey key;
final Signal<String> title;
final Widget child;
```

`title` drives breadcrumbs. Pages write `AdaptivePaneScope.maybeOf(context)?.title.value = …`.

When you construct panes yourself (no router), you own the `Signal<String>` and must `dispose` it.

## `AdaptivePaneScope`

`InheritedWidget` around each visible column (including the empty right slot). Non-null **only** inside the two-column viewport.

Replaces 2.x `inSlidingWindow` / `SlidingPaneScope` / `SlidingPageTitle`.

### Constructor

```dart
const AdaptivePaneScope({
  super.key,
  required int index,
  required int depth,
  required Signal<String> title,
  required VoidCallback pop,
  required super.child,
})
```

The viewport sets `pop` to `onPop` (or a no-op if `onPop` is null). The built-in shell passes `() => router.maybePop()`.

### Fields

```dart
final int index;            // stack index, 0 = root
final int depth;            // current stack length
final Signal<String> title; // this pane's breadcrumb
final VoidCallback pop;     // usually maybePop
```

### `isTop`

```dart
bool get isTop => depth > 0 && index == depth - 1;
```

### `showBack`

```dart
bool get showBack => depth > 1 && isTop;
```

True on the stack-top pane when it is not the branch root — use for an AppBar back button.

### `maybeOf` / `of`

```dart
static AdaptivePaneScope? maybeOf(BuildContext context)
static AdaptivePaneScope of(BuildContext context)
```

`maybeOf` is null in 1-column mode, on root-navigator overlays, and off-shell. `of` asserts `'AdaptivePaneScope not found'`.

Prefer `maybeOf` in shared pages that also run compact.

### `updateShouldNotify`

```dart
@override
bool updateShouldNotify(AdaptivePaneScope oldWidget) {
  return index != oldWidget.index ||
      depth != oldWidget.depth ||
      pop != oldWidget.pop ||
      title != oldWidget.title;
}
```

Notifies when index / depth / `pop` / the **signal instance** change (back button). Title **text** changes go through the `Signal`, not this notify.
