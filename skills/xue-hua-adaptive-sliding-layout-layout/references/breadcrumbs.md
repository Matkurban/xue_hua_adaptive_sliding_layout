# AdaptiveBreadcrumbs and breadcrumb typedefs

Source: `lib/src/layout/breadcrumbs.dart`.

## `AdaptiveBreadcrumbItemBuilder`

```dart
typedef AdaptiveBreadcrumbItemBuilder = Widget Function(
  BuildContext context,
  SlidingPane pane,
  bool isLast,
  VoidCallback? onTap,
);
```

One crumb. `onTap` is `null` for the last visible item.

## `AdaptiveBreadcrumbSeparatorBuilder`

```dart
typedef AdaptiveBreadcrumbSeparatorBuilder =
    Widget Function(BuildContext context, int index);
```

Separator after visible item `index` (the left-hand crumb).

## `AdaptiveBreadcrumbsBuilder`

```dart
typedef AdaptiveBreadcrumbsBuilder = Widget Function(
  BuildContext context,
  List<SlidingPane> panes,
  ValueChanged<SlidingPane> onSelect,
);
```

Replace the whole strip. Still invoked only when `AdaptiveShellRoute.showBreadcrumbs` is true. The built-in shell’s `onSelect` is `router.popUntil((m) => m.pageKey == pane.key)`.

## `AdaptiveBreadcrumbs`

Draws the full-stack titles. Clicking a non-last crumb calls `onSelect`.

### Constructor

```dart
const AdaptiveBreadcrumbs({
  super.key,
  required List<SlidingPane> panes,
  required ValueChanged<SlidingPane> onSelect,
  double height = 32,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12),
  Color? backgroundColor,
  AdaptiveBreadcrumbItemBuilder? itemBuilder,
  AdaptiveBreadcrumbSeparatorBuilder? separatorBuilder,
})
```

### Fields

| Field | Default | Meaning |
| --- | --- | --- |
| `panes` | required | Full branch stack, not only the visible columns. |
| `onSelect` | required | Fired with the tapped pane when it is not last. |
| `height` | `32` | Strip height. |
| `padding` | horizontal `12` | List padding. |
| `backgroundColor` | `null` → `ColorScheme.surfaceContainerLow` | Strip color. |
| `itemBuilder` | `null` → `InkWell` + `Text` (`labelMedium`; last item `w600` / `onSurface`, others `w400` / `onSurfaceVariant`) | One crumb. |
| `separatorBuilder` | `null` → 16px `Icons.chevron_right` in `outline` | Between crumbs. |

### `build`

```dart
@override
Widget build(BuildContext context)
```

Wrapped in `SignalBuilder` so `pane.title.value` updates rebuild the strip.

- Panes whose `title.value` is empty are omitted.
- If none remain, `SizedBox.shrink()`.
- Horizontal `ListView.separated`.
- Last visible crumb: `onTap == null` (not tappable).
