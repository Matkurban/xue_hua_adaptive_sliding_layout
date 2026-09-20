# LayoutBreakpoints and AppBreakpoints

Source: `lib/src/layout/layout_breakpoints.dart`.

Width bands only. Not device type, not orientation.

`ponytail:` the viewport supports 1 or 2 columns. Three-plus columns would change `visibleColumnCount` and teach `SlidingPaneViewport` to lay out N panes.

## `LayoutBreakpoints`

### Constructor

```dart
const LayoutBreakpoints({
  double compactMaxWidth = 600,
  double expandedMinWidth = 840,
})
```

Material medium defaults.

### Fields

```dart
final double compactMaxWidth;   // exclusive upper bound of compact
final double expandedMinWidth;  // inclusive lower bound of expanded
```

### `isCompact`

```dart
bool isCompact(double width) => width < compactMaxWidth;
```

Single-column full-screen `Navigator` stack. Host typically draws a bottom bar.

### `isMedium`

```dart
bool isMedium(double width) =>
    width >= compactMaxWidth && width < expandedMinWidth;
```

Still **1** column (`Navigator`), same as compact. Host uses `shell.isMedium` for chrome (rail vs bar).

### `isExpanded`

```dart
bool isExpanded(double width) => width >= expandedMinWidth;
```

Two-column `SlidingPaneViewport` (last two panes + optional sash).

### `visibleColumnCount`

```dart
int visibleColumnCount(double width) => isExpanded(width) ? 2 : 1;
```

| Width (defaults) | Band | Columns |
| --- | --- | --- |
| `< 600` | compact | 1 |
| `600–839` | medium | 1 |
| `≥ 840` | expanded | 2 |

Crossing `expandedMinWidth` rebuilds page `State` (Navigator tree ↔ viewport tree).

## `AppBreakpoints`

```dart
typedef AppBreakpoints = LayoutBreakpoints;
```

Name-compatible alias for 2.x `AppBreakpoints`. Same class.
