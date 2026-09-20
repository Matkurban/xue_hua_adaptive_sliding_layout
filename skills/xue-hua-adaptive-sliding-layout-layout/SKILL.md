---
name: xue-hua-adaptive-sliding-layout-layout
description: >-
  Build xue_hua_adaptive_sliding_layout chrome and columns: LayoutBreakpoints,
  AdaptiveShellState, SlidingPaneViewport, SlidingPane, AdaptivePaneScope,
  AdaptiveBreadcrumbs, paneBuilder, sash, and layout-without-a-router.
  Use when customizing panes, breadcrumbs, breakpoints, or titles.
license: Apache-2.0
---

# Layout: panes, breakpoints, breadcrumbs

`SlidingPaneViewport`, `SlidingPane`, and `AdaptiveBreadcrumbs` stay public if you only want the sliding columns. Route-table knobs on `AdaptiveShellRoute` are signed in the **routing** skill; this skill is how they behave.

API: [references/breakpoints.md](references/breakpoints.md), [references/shell-state.md](references/shell-state.md), [references/panes.md](references/panes.md), [references/viewport.md](references/viewport.md), [references/breadcrumbs.md](references/breadcrumbs.md).

## Guidelines

* Breakpoints use **window width**, not device type or orientation. Defaults: compact `< 600`, medium `600–839` (still 1 column), expanded `≥ 840` (2 columns). The viewport is 1 or 2 columns only (`ponytail:` three-plus columns would change `visibleColumnCount` and `SlidingPaneViewport`).
* Crossing 840 rebuilds page `State` (Navigator tree ↔ viewport tree). Keep durable state in the URL, a signal, or a host store.
* `AdaptivePaneScope.maybeOf(context)` is non-null **only** inside a two-column pane. Use it instead of 2.x `inSlidingWindow` / `SlidingPageTitle`. 1-column mode, overlays, and off-shell pages return null.
* Async / localized titles: `AdaptivePaneScope.maybeOf(context)?.title.value = subject`. `AdaptiveRoute.title` is not re-evaluated on locale change.
* Pane overlays are **clipped**. Dialogs, menus, and sheets inside a column: `useRootNavigator: AdaptivePaneScope.maybeOf(context) != null`.
* `paneBuilder(context, index, child)` wraps each column. `index == panes.length` is the empty right slot. Default: card in 2-col, flat in 1-col.
* `resizeHandleBuilder` changes the sash **look** only. Hit target stays 44px; `SlidingPaneViewport.resizeHandleKey` / `visibleLeftPaneKey` / `visibleRightPaneKey` are test keys (the visible-pane keys sit on a non-page sibling so swapping columns does not unload the pane `Navigator`).
* Sash drag updates locally; `onLeftPaneFractionChanged` fires on pointer-up. The built-in shell writes `router.leftPaneFraction.value` then calls `AdaptiveShellRoute.onLeftPaneFractionChanged`. Fraction is clamped with `SlidingPaneViewport.clampLeftPaneFraction` (if min>max, midpoint).
* `AdaptiveBranch.placeholder` wins over `AdaptiveShellRoute.placeholder` for the empty right pane.
* `showBreadcrumbs` gates the strip (expanded). Click a non-last crumb → `router.popUntil((m) => m.pageKey == pane.key)`. Empty titles are omitted; the last crumb is not tappable.
* Escape calls `maybePop` when `escapePops` is true, unless the primary focus is an `EditableTextState`.
* On compact, `hidesBottomBarWhenPushed` (default `true`) covers the host bottom bar. Medium rail and expanded panes keep host chrome. `fullscreen` / `fullscreenDialog` cover the shell at every width.
* Theme colors come from `Theme.of(context)`. 1-column page transitions use `ThemeData.pageTransitionsTheme`.
* Off-screen panes: ticker / focus / hit-testing disabled; `PageStorage` + pane `key` keep `State` when they slide back.

## Examples

### Shell chrome: compact bar vs rail

```dart
AdaptiveShellRoute(
  builder: (context, shell, child) {
    return Scaffold(
      body: shell.isCompact
          ? child
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: (i) => shell.goBranch(i),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.mail), label: Text('Mail')),
                  ],
                ),
                Expanded(child: child),
              ],
            ),
      bottomNavigationBar: shell.isCompact
          ? NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: shell.goBranch,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.mail), label: 'Mail'),
              ],
            )
          : null,
    );
  },
  branches: branches,
)
```

Always put `child` in the content area.

### Live pane title

```dart
@override
void initState() {
  super.initState();
  loadSubject().then((text) {
    if (!mounted) return;
    AdaptivePaneScope.maybeOf(context)?.title.value = text;
  });
}
```

### Dialog from a pane

```dart
showDialog<void>(
  context: context,
  useRootNavigator: AdaptivePaneScope.maybeOf(context) != null,
  builder: (context) => const AlertDialog(title: Text('…')),
);
```

### Custom breakpoints + sash

```dart
AdaptiveShellRoute(
  breakpoints: const LayoutBreakpoints(
    compactMaxWidth: 600,
    expandedMinWidth: 1024,
  ),
  resizable: true,
  initialLeftPaneFraction: 0.4,
  minLeftPaneFraction: 0.25,
  minRightPaneFraction: 0.3,
  onLeftPaneFractionChanged: (value) => savedFraction.value = value,
  builder: builder,
  branches: branches,
)
```

### Layout without a router

```dart
SlidingPaneViewport(
  panes: [
    SlidingPane(
      key: const ValueKey('list'),
      title: signal('Mail'),
      child: const MailList(),
    ),
    SlidingPane(
      key: const ValueKey('detail'),
      title: signal('Thread'),
      child: const ThreadView(),
    ),
  ],
  visibleCount: 2,
  onPop: () {},
)
```

You own the `Signal<String>` titles and must dispose them.

### Custom breadcrumb strip

```dart
breadcrumbsBuilder: (context, panes, onSelect) {
  return AdaptiveBreadcrumbs(
    panes: panes,
    onSelect: onSelect,
    height: 40,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
  );
},
```

To draw titles in **your** chrome, read `AdaptiveRouter.of(context).matches.value.branchMatches` (each match has `title` and `name`).
