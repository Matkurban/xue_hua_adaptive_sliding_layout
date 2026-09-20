# Sliding viewport

Source: `lib/src/layout/sliding_pane_viewport.dart`.

## `SlidingPaneViewport`

Horizontal sliding viewport that always shows the last `visibleCount` panes of `panes`.

## Constructor

```dart
const SlidingPaneViewport({
  super.key,
  required List<SlidingPane> panes,
  required int visibleCount,
  VoidCallback? onPop,
  Widget? placeholder,
  double leftPaneFraction = defaultLeftPaneFraction,
  double minLeftPaneFraction = defaultMinLeftPaneFraction,
  double minRightPaneFraction = defaultMinRightPaneFraction,
  ValueChanged<double>? onLeftPaneFractionChanged,
  bool? resizeLeftPane,
  Duration slideDuration = defaultSlideDuration,
  Curve slideCurve = defaultSlideCurve,
  SlidingPaneFrameBuilder? paneBuilder,
  WidgetBuilder? resizeHandleBuilder,
})
```

## Static defaults and test keys

```dart
static const double defaultLeftPaneFraction = 0.5;
static const double defaultMinLeftPaneFraction = 0.3;
static const double defaultMinRightPaneFraction = 0.3;
static const Duration defaultSlideDuration = Duration(milliseconds: 280);
static const Curve defaultSlideCurve = Curves.easeOutCubic;

static const Key resizeHandleKey = Key('pane-resize-handle');
static const Key visibleLeftPaneKey = Key('sliding-visible-left');
static const Key visibleRightPaneKey = Key('sliding-visible-right');
```

`visibleLeftPaneKey` / `visibleRightPaneKey` hang on a non-page sibling (`IgnorePointer` + `SizedBox.expand`) so swapping the visible pair does not unload the pane `Navigator`.

## Fields

| Field                          | Meaning                                                                                                                                      |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `panes`                        | Full stack, not only the visible pair.                                                                                                       |
| `visibleCount`                 | How many columns to show. Values `< 1` are treated as `1`.                                                                                   |
| `onPop`                        | AppBar back / `LocalHistoryEntry` on the pane navigator. `null` ⇒ no back entry is registered. Built-in shell: `() => router.maybePop()`.    |
| `placeholder`                  | Content of the empty right column when `panes.length < visibleCount`.                                                                        |
| `leftPaneFraction`             | Left width / viewport width when `visibleCount == 2`. When `onLeftPaneFractionChanged` is null, the State keeps the fraction itself.         |
| `minLeftPaneFraction`          | Lower clamp for the left fraction.                                                                                                           |
| `minRightPaneFraction`         | Right minimum; left max is `1 - this`.                                                                                                       |
| `onLeftPaneFractionChanged`    | Pointer-up only. Drag uses viewport-local coordinates and does not notify. While dragging, widget updates to `leftPaneFraction` are ignored. |
| `resizeLeftPane`               | Show the sash. Default: on when `visibleCount == 2`.                                                                                         |
| `slideDuration` / `slideCurve` | Strip translate animation when the visible window moves.                                                                                     |
| `paneBuilder`                  | See `SlidingPaneFrameBuilder`. `index == panes.length` is the placeholder slot.                                                              |
| `resizeHandleBuilder`          | Visual only. `Listener`, resize cursor, and 44px hit width stay in the package.                                                              |

## `clampLeftPaneFraction`

```dart
static double clampLeftPaneFraction(
  double fraction, {
  double minLeftPaneFraction = defaultMinLeftPaneFraction,
  double minRightPaneFraction = defaultMinRightPaneFraction,
})
```

1. `minLeft = minLeftPaneFraction.clamp(0.0, 1.0)`
2. `maxLeft = (1.0 - minRightPaneFraction.clamp(0.0, 1.0)).clamp(0.0, 1.0)`
3. If `maxLeft < minLeft`, return the midpoint of those two, clamped to `[0, 1]` (avoids NaN).
4. Else `fraction.clamp(minLeft, maxLeft)`.

## `createState`

```dart
@override
State<SlidingPaneViewport> createState() => _SlidingPaneViewportState();
```

Standard `StatefulWidget` override. The State is private.

## Layout behavior

- Non-finite or `<= 0` width/height → `SizedBox.shrink()`.
- Two columns: left width = `width * fraction`, right = remainder. Sash is a 44px-wide `Listener` centered on the split (`hitExtent = 44`). Visual default is a 2px `outline` line.
- The strip is `ClipRect` + `OverflowBox` + `Transform.translate`. `clipBehavior: Clip.hardEdge` on the viewport stack — pane overlays are clipped.
- Off-screen panes: `TickerMode` off, `ExcludeFocus`, `IgnorePointer`. `PageStorage` + `PageStorageKey(pane.key)` keep scroll/state.
- Each visible frame is wrapped in `AdaptivePaneScope`.
- Default 2-col decoration is a card (`_PaneCardShell`). Default 1-col is flat, with a left `outlineVariant` divider on `index > 0` when not using `paneBuilder`.
