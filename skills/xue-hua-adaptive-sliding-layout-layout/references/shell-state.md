# AdaptiveShellState and AdaptiveShellScope

Built each layout by the internal shell from `LayoutBuilder` + router signals.

## `AdaptiveShellState`

Source: `lib/src/router/adaptive_shell_state.dart`.

Argument of `AdaptiveShellRoute.builder`. Also `AdaptiveShellScope.of(context)` under that chrome.

### Constructor

```dart
AdaptiveShellState({
  required int currentIndex,
  required int branchCount,
  required double width,
  required LayoutBreakpoints breakpoints,
  required Signal<double> leftPaneFraction,
  required void Function(int index, {bool initialLocation}) goBranch,
})
```

The built-in shell passes:

- `currentIndex: router.currentBranch.value`
- `branchCount: shell.branches.length`
- `width`: `constraints.maxWidth` if finite, else `MediaQuery.sizeOf(context).width`
- `breakpoints: AdaptiveShellRoute.breakpoints`
- `leftPaneFraction: router.leftPaneFraction`
- `goBranch: router.goBranch` (same tear-off; see the **navigation** skill)

### Fields

| Field              | Meaning                                                                                                                           |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| `currentIndex`     | Selected `AdaptiveBranch` index.                                                                                                  |
| `branchCount`      | `branches.length`.                                                                                                                |
| `width`            | Shell `LayoutBuilder` width.                                                                                                      |
| `breakpoints`      | This shell’s bands.                                                                                                               |
| `leftPaneFraction` | Shared sash fraction signal. Written on sash pointer-up. During drag the viewport updates locally and does not write this signal. |
| `goBranch`         | Switch tab. `initialLocation: true` ignores the stored stack and goes to `AdaptiveBranch.initialLocation`.                        |

### Width getters

```dart
bool get isCompact => breakpoints.isCompact(width);
bool get isMedium => breakpoints.isMedium(width);
bool get isExpanded => breakpoints.isExpanded(width);
int get visibleColumnCount => breakpoints.visibleColumnCount(width);
```

Use `isCompact` for a `NavigationBar`, `isMedium` / `isExpanded` for a rail. `visibleColumnCount` is 2 only when expanded.

## `AdaptiveShellScope`

Source: `lib/src/router/adaptive_shell_scope.dart`.

`InheritedWidget` wrapping the shell builder’s output.

### Constructor

```dart
const AdaptiveShellScope({
  super.key,
  required AdaptiveShellState state,
  required super.child,
})
```

### Fields

```dart
final AdaptiveShellState state;
```

### `maybeOf` / `of`

```dart
static AdaptiveShellState? maybeOf(BuildContext context)
static AdaptiveShellState of(BuildContext context)
```

`maybeOf` is null outside the shell (fullscreen overlay, a route with no shell). `of` asserts `'AdaptiveShellState not found in context'`.

### `updateShouldNotify`

```dart
@override
bool updateShouldNotify(AdaptiveShellScope oldWidget) {
  return state.currentIndex != oldWidget.state.currentIndex ||
      state.width != oldWidget.state.width ||
      state.breakpoints != oldWidget.state.breakpoints;
}
```

Dependents rebuild on tab index, width, or breakpoint **instance**. `leftPaneFraction` is a `Signal` — subscribe with `SignalBuilder`.
