# xue_hua_adaptive_sliding_layout

[中文文档](README.zh-CN.md)

Adaptive mobile / desktop multi-column sliding layout for Flutter. The host owns routing, DI, and l10n. This package only owns **breakpoints**, a **per-tab sliding stack**, the **viewport**, and optional **named-route intercept**.

It does **not** depend on `go_router`, GetIt, or any localization package. The only extra dependency is `signals_flutter`.

- [What problem it solves](#what-problem-it-solves)
- [Component catalog](#component-catalog)
- [Breakpoints and visible columns](#breakpoints-and-visible-columns)
- [How the pieces connect](#how-the-pieces-connect)
- [API by class](#api-by-class)
  - [LayoutBreakpoints](#layoutbreakpoints)
  - [SlidingShell](#slidingshell)
  - [SlidingWindowController](#slidingwindowcontroller)
  - [SlidingWindowPage](#slidingwindowpage)
  - [AdaptiveNavigator](#adaptivenavigator)
  - [AdaptiveNavigatorFallback](#adaptivenavigatorfallback)
  - [AdaptiveRouteArgs](#adaptiverouteargs)
  - [MultiColumnScaffold](#multicolumnscaffold)
  - [SlidingWindowViewport](#slidingwindowviewport)
  - [SlidingActions and SlidingBackButton](#slidingactions-and-slidingbackbutton)
  - [SlidingPageTitle](#slidingpagetitle)
  - [SlidingWindowScope, SlidingPaneScope, inSlidingWindow](#slidingwindowscope-slidingpanescope-inslidingwindow)
- [Integrate in a real project](#integrate-in-a-real-project)
- [Caveats](#caveats)
- [Example](#example)
- [Tests](#tests)

## What problem it solves

On a phone-width window, pages stay on the host `Navigator` / GoRouter.

From medium width up, intercepted pages **leave** that navigator and sit in a sliding stack owned by the current tab. A wide window shows the last two pages side by side. Deeper pages slide older ones off to the left instead of opening a third column.

Typical host wiring:

1. One [`SlidingWindowController`](lib/src/sliding_window_controller.dart) per tab, or a [`SlidingShell`](lib/src/sliding_shell.dart) that creates them.
2. Each tab wrapped in [`MultiColumnScaffold`](lib/src/multi_column_scaffold.dart).
3. All pushes go through [`AdaptiveNavigator`](lib/src/adaptive_navigator.dart), which either writes the sliding stack or calls your [`AdaptiveNavigatorFallback`](lib/src/adaptive_navigator.dart).

## Component catalog

| Type | Role | Who creates it | Who consumes it |
| --- | --- | --- | --- |
| [`LayoutBreakpoints`](lib/src/layout_breakpoints.dart) (`AppBreakpoints`) | Window-width bands: compact / medium / expanded | nobody (static) | host layout + `SlidingShell` |
| [`SlidingShell`](lib/src/sliding_shell.dart) | One controller per tab, viewport width, shared left-pane fraction | host, once | host layout + `AdaptiveNavigator` |
| [`SlidingWindowController`](lib/src/sliding_window_controller.dart) | Stack of pages for one tab | `SlidingShell.init` or host | viewport + navigator |
| [`SlidingWindowPage`](lib/src/sliding_window_page.dart) | One stack entry (key, name, title, builder, completer) | controller | viewport, breadcrumbs |
| [`MultiColumnScaffold`](lib/src/multi_column_scaffold.dart) | Tab chrome: optional leading, breadcrumbs, Escape, viewport | host per tab | user |
| [`SlidingWindowViewport`](lib/src/sliding_window_viewport.dart) | Draws the last 1–2 panes; optional sash | `MultiColumnScaffold` | user |
| [`AdaptiveNavigator`](lib/src/adaptive_navigator.dart) | Navigator-paired verbs; wide stack vs fallback | host, once | every route call |
| [`AdaptiveNavigatorFallback`](lib/src/adaptive_navigator.dart) | Compact / unhandled routes | host implements | `AdaptiveNavigator` |
| [`AdaptiveRouteArgs`](lib/src/adaptive_navigator.dart) | `name` + extra + path/query for `buildPage` | navigator | host page factory |
| [`SlidingActions`](lib/src/sliding_actions.dart) | Injects `pop` for AppBar / Escape / back button | `MultiColumnScaffold` | viewport + `SlidingBackButton` |
| [`SlidingBackButton`](lib/src/sliding_back_button.dart) | Back control only on the right-most non-root pane | host page | user |
| [`SlidingPageTitle`](lib/src/sliding_page_title.dart) | Breadcrumb title; `report` / `humanize` | viewport | host page |
| [`SlidingWindowScope`](lib/src/sliding_window_scope.dart) | Exposes the tab controller | `MultiColumnScaffold` | menus / custom pop |
| [`SlidingPaneScope`](lib/src/sliding_window_scope.dart) | Pane index + `showBack` | viewport | `from:` pushes, back button |
| [`inSlidingWindow`](lib/src/sliding_window_scope.dart) | `true` inside the sliding viewport | — | overlay / menu hosts |

## Breakpoints and visible columns

[`LayoutBreakpoints`](lib/src/layout_breakpoints.dart) uses **window width**, not device type or orientation.

| Width | Band | Visible columns | Sliding stack |
| --- | --- | --- | --- |
| `< 600` | compact | 1 | **off** — host navigator |
| `600–839` | medium | 1 | **on** — one visible pane |
| `≥ 840` | expanded | 2 | **on** — last two panes |

[`SlidingShell.isSlidingActive`](lib/src/sliding_shell.dart) is `true` after `init()` when the width is **not** compact. That is the flag [`AdaptiveNavigator`](lib/src/adaptive_navigator.dart) uses to intercept vs fall back.

`visibleColumnCount` is `2` only in the expanded band; otherwise `1`. Stack **depth can be larger** than the visible column count. Home and Inbox can stay on the stack while the viewport only shows Reply + Attachment.

## How the pieces connect

```
Host app
  ├─ SlidingShell          tab stacks + width + leftPaneFraction
  ├─ AdaptiveNavigator     verbs → stack or fallback
  │    └─ Fallback         compact / handlesRoute == false
  └─ per tab: MultiColumnScaffold
       ├─ SlidingWindowScope / SlidingActions
       └─ SlidingWindowViewport → SlidingWindowController pages
```

Wide + `handlesRoute(name)`: write the current tab stack. Compact, or a name the host rejects: call the fallback. The controller (`push` / `openAfter` / `replace`) is an implementation detail; day-to-day calls should go through `AdaptiveNavigator`.

## API by class

### LayoutBreakpoints

Sealed helper. Alias: `typedef AppBreakpoints = LayoutBreakpoints`.

| Member | Meaning |
| --- | --- |
| `compactMaxWidth` (`600`) | Widths below this are compact. |
| `expandedMinWidth` (`840`) | Widths at or above this are expanded (two columns). |
| `isCompact(width)` | `width < 600` |
| `isExpanded(width)` | `width >= 840` |
| `visibleColumnCount(width)` | `2` if expanded, else `1` |

Medium is “not compact and not expanded”: sliding on, one column.

### SlidingShell

Owns one [`SlidingWindowController`](lib/src/sliding_window_controller.dart) per tab plus shared viewport signals.

```dart
final shell = SlidingShell(tabCount: 2)..init();
// LayoutBuilder →
shell.updateViewportWidth(width);
```

| Member | Role |
| --- | --- |
| `tabCount` | How many controllers `init()` creates. |
| `init()` | Allocates `stacks`. Call once before reading stacks or `isSlidingActive`. |
| `dispose()` | Completes pending page futures, disposes controllers, marks uninitialized. |
| `updateViewportWidth(width)` | Writes `viewportWidth` if it changed. Drive this from `LayoutBuilder`. |
| `changePage(index)` | Sets `currentIndex` (does not pop stacks). |
| `stacks` | `List<SlidingWindowController>` after `init`. |
| `currentStack` | `stacks[currentIndex]`. |
| `currentIndex` | `Signal<int>`, default `0`. |
| `viewportWidth` | `Signal<double>`, default `0`. |
| `leftPaneFraction` | Shared sash fraction, default `0.5`. Bind this across tabs. |
| `isInitialized` | Whether `init()` has run. |
| `isCompact` / `isExpanded` | From current `viewportWidth`. |
| `isSlidingActive` | `isInitialized && !isCompact`. |
| `visibleColumnCount` | `1` or `2` from current width. |

You can skip `SlidingShell` and construct controllers yourself if you pass matching `isSlidingActive` / `currentStack` closures into `AdaptiveNavigator`.

### SlidingWindowController

Stack for **one** tab. The root page cannot be popped. Hosts normally call `AdaptiveNavigator`, not these methods.

| Member | Role |
| --- | --- |
| `pages` | `Signal<List<SlidingWindowPage>>`. |
| `canPop` | `depth > 1`. |
| `depth` | `pages.length`. |
| `indexOfName(name)` | Last index with that non-empty `name`, or `-1`. |
| `visiblePages(visibleCount)` | Trailing slice the viewport should show. |
| `ensureRoot(...)` | Pushes the root once (`ValueKey('sliding-root')`). No-op if the stack is not empty. |
| `push` | Append one page (Push Slide). Depth +1. |
| `openAfter(keepCount, ...)` | Keep the first `keepCount` pages, drop the rest, then push. `keepCount >= depth` or empty stack → `push`. `keepCount` is clamped to at least `1`. |
| `openSecondary` | `openAfter(1, ...)` — stack becomes `[root, page]`. |
| `replace` | Swap **stack top only** (including root). Does not clear middle pages. |
| `pop([result])` | Pop the top page and complete its future. `false` at root. |
| `popToRoot()` | Pop until only the root remains. |
| `popUntil(predicate)` | Pop while the top page fails `predicate`. |
| `dispose()` | Complete leftovers, clear `pages`, dispose the signal. |

### SlidingWindowPage

One stack entry.

| Field | Role |
| --- | --- |
| `key` | Identity for viewport keep-alive and `PageStorageKey`. Root is `ValueKey('sliding-root')`. |
| `name` | Route id (path or type name). Empty names are skipped in breadcrumbs. |
| `title` | `Signal<String>` shown in breadcrumbs; update via `SlidingPageTitle.report`. |
| `builder` | Builds the pane subtree. |
| `completer` | Completes when the page is popped or replaced. |
| `dispose()` | Disposes `title`. |

### AdaptiveNavigator

Wide-window navigation. Verbs pair like Flutter `Navigator`: if there is `push`, there is `pushNamed`.

```dart
final navigator = AdaptiveNavigator(
  isSlidingActive: () => shell.isSlidingActive,
  currentStack: () => shell.currentStack,
  buildPage: (args) => /* Widget for args.name, or null */,
  handlesRoute: (name) => name != '/photo',
  resolveTitle: (name) => /* breadcrumb label */,
  fallback: MyNavigatorFallback(),
);
```

| Constructor | Role |
| --- | --- |
| `isSlidingActive` | When `false`, every call goes to `fallback`. |
| `currentStack` | Which tab stack to write. |
| `buildPage` | Maps [`AdaptiveRouteArgs`](lib/src/adaptive_navigator.dart) to a widget. `null` → fallback. |
| `handlesRoute` | Wide only: `false` skips the sliding stack (fullscreen photo, login, …). |
| `fallback` | Compact and unhandled names. |
| `resolveTitle` | Initial breadcrumb / page title. Default: [`SlidingPageTitle.humanize`](lib/src/sliding_page_title.dart). |

| Call | Wide + handled | Otherwise |
| --- | --- | --- |
| `push` / `pushNamed` (no `from`) | append one page | `fallback.push` / `pushNamed` |
| `push` / `pushNamed` (`from: context`) | pane-aware `openAfter` | same fallback |
| `pushReplacement` / `pushReplacementNamed` | replace **stack top only** | `fallback.pushReplacement*` |
| `pushAndRemoveUntil` / `pushNamedAndRemoveUntil` | `popUntil(predicate)` then push (`untilRoot` → `[root, page]`) | `fallback.pushAndRemoveUntil*` |
| `pop` / `canPop` | sliding stack if it can pop | fallback |
| `popToRoot` | pop sliding stack to root | `fallback.popToRoot` |

`from:` exists **only** on `push` / `pushNamed`. It means “which pane you pushed from”, not a Flutter `Navigator` feature.

Rules for `push` / `pushNamed` + `from`:

1. `keepCount = fromPaneIndex + 1`.
2. If the same non-empty `name` already exists at `existing >= keepCount`, **jump back** with `openAfter(existing)`.
3. Else `openAfter(keepCount)` so the new page sits immediately after the pane you tapped.

Without `from`, the call is a plain stack `push`.

`AdaptiveNavigator.untilRoot` is `page.key == AdaptiveNavigator.rootPageKey` (`ValueKey('sliding-root')`). Use it for peer replace:

```dart
shell.changePage(chatTabIndex);
navigator.pushNamedAndRemoveUntil('/chat', AdaptiveNavigator.untilRoot);
```

That tab-switch + peer replace is **host policy**, not a package callback.

### AdaptiveNavigatorFallback

Implement this with your existing router. Compact windows and any name that fails `handlesRoute` always hit these methods.

| Method | Typical host wiring |
| --- | --- |
| `push` / `pushReplacement` | `Navigator.push` / `pushReplacement` (`MaterialPageRoute`) |
| `pushNamed` | `context.pushNamed` (GoRouter) or push a page you build yourself |
| `pushReplacementNamed` | GoRouter: `context.goNamed` (replace the shell location). Plain `Navigator`: `pushReplacement` |
| `pushAndRemoveUntil` | Often `pushReplacement` on compact (no sliding stack) |
| `pushNamedAndRemoveUntil` | Often `pushNamed` or `pushReplacementNamed` |
| `pop` / `canPop` | Root navigator / GoRouter |
| `popToRoot` | `Navigator.popUntil(..., (r) => r.isFirst)` |

The sliding `predicate` is not meaningful on a compact `Navigator`. Mapping `pushAndRemoveUntil` → `pushReplacement` is the usual compact stand-in.

### AdaptiveRouteArgs

Passed to `buildPage`.

| Field | Role |
| --- | --- |
| `name` | Route id the host registered (`/thread/:id`, `chat`, …). |
| `extra` | Opaque object from `pushNamed(..., extra:)`. |
| `pathParameters` | e.g. `{'id': '12'}`. |
| `queryParameters` | Stringified query (`dynamic` values become `toString()`). |

### MultiColumnScaffold

Per-tab shell: optional leading column, breadcrumbs, Escape, and the viewport. First build calls `controller.ensureRoot`.

```dart
MultiColumnScaffold(
  controller: shell.stacks[0],
  root: const HomeTab(),
  rootName: 'Home',
  visibleCount: columns,
  showBreadcrumbs: LayoutBreakpoints.isExpanded(width),
  onEscapePop: navigator.pop,
  leftPaneFraction: shell.leftPaneFraction.value,
  onLeftPaneFractionChanged: (value) => shell.leftPaneFraction.value = value,
)
```

| Parameter | Role |
| --- | --- |
| `controller` | This tab’s stack. |
| `root` / `rootName` | Root widget and its stack name. `ensureRoot` runs on first build. |
| `visibleCount` | How many panes the viewport shows (`1` or `2`). |
| `leading` | Optional left chrome (list, rail inset). |
| `showBreadcrumbs` | Draw the **full** stack (not only visible panes). Tapping a non-last crumb `popUntil`s that page. |
| `onEscapePop` | Pop when Escape is pressed and focus is not in a text field. Also written into [`SlidingActions`](lib/src/sliding_actions.dart) for the pane AppBar and [`SlidingBackButton`](lib/src/sliding_back_button.dart). Default: `controller.pop`. Prefer `AdaptiveNavigator.pop` so compact and wide share one verb. |
| `leftPaneFraction` | Left pane width / viewport (two-column only). Default `0.5`. |
| `minLeftPaneFraction` / `minRightPaneFraction` | Clamp so neither column can collapse. Default `0.3` (30%–70%). |
| `onLeftPaneFractionChanged` | Fires on **pointer up**, not during the drag. Omit it and the viewport keeps the fraction itself. |
| `resizeLeftPane` | Show the sash. Default: on when `visibleCount == 2`. `false` locks the split. |

Single-column and compact layouts have no sash.

### SlidingWindowViewport

You usually get this through `MultiColumnScaffold`. Same sash parameters as above, plus:

| Parameter | Role |
| --- | --- |
| `placeholder` | Shown in an empty second column when depth is 1 and `visibleCount == 2`. |
| `resizeHandleKey` / `visibleLeftPaneKey` / `visibleRightPaneKey` | Keys for tests. |

`clampLeftPaneFraction` is the shared clamp used by the sash.

The sash tracks the pointer with viewport-absolute `globalToLocal` (no drag slop, no accumulated `delta`).

### SlidingActions and SlidingBackButton

`MultiColumnScaffold` writes [`SlidingActions`](lib/src/sliding_actions.dart). The viewport AppBar back control and [`SlidingBackButton`](lib/src/sliding_back_button.dart) call `SlidingActions.pop`. They never talk to your router class.

| API | Role |
| --- | --- |
| `SlidingActions.pop` | Callback injected by the scaffold. |
| `SlidingActions.maybeOf` / `of` | Read from a pane. |
| `SlidingBackButton(onPressed:)` | Optional override. Default: `SlidingActions.pop`, then `controller.pop`. |

`SlidingBackButton` renders only on the **right-most visible pane** when that pane is not the root (`SlidingPaneScope.showBack`).

### SlidingPageTitle

Each page holds a reactive `title`. From a page:

```dart
SlidingPageTitle.maybeOf(context)?.report('Alice');
```

Empty titles and unchanged titles are ignored. `report` writes on the **next frame** so the first layout can still sync from `AppBar.title`.

`SlidingPageTitle.humanize(name)` turns a path or type name into a label: strips `/`, `:params`, and `Page` / `View` suffixes, then inserts spaces at camelCase boundaries. It is **not** l10n — pass `resolveTitle` for real copy.

### SlidingWindowScope, SlidingPaneScope, inSlidingWindow

| API | Role |
| --- | --- |
| `SlidingWindowScope.controller` | Current tab stack. |
| `SlidingWindowScope.maybeOf` / `of` | Read the scope. |
| `SlidingPaneScope.index` | Pane index in the stack (`0` = root). |
| `SlidingPaneScope.depth` | Current stack depth. |
| `isStackTop` / `showBack` | Top pane; back only when `depth > 1` and this pane is the top. |
| `inSlidingWindow(context)` | `true` inside the desktop sliding viewport. |

Pane overlays are **clipped** to the column. Menus and sheets should use the **root** overlay:

```dart
PopupMenuButton<String>(
  useRootNavigator: inSlidingWindow(context),
  // ...
)
```

`AdaptiveNavigator.push(..., from: context)` reads `SlidingPaneScope` from `from` to decide `openAfter`.

## Integrate in a real project

Do not mix `context.go` / raw `Navigator.push` with `AdaptiveNavigator` for the same flows. Wide stack and root route will diverge.

### 1. Depend on the package

```yaml
dependencies:
  xue_hua_adaptive_sliding_layout:
    path: ../package/xue_hua_adaptive_sliding_layout
```

### 2. Create the shell and feed width

```dart
final shell = SlidingShell(tabCount: 2)..init();

// In the widget that owns the window:
LayoutBuilder(
  builder: (context, constraints) {
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : MediaQuery.sizeOf(context).width;
    shell.updateViewportWidth(width);
    // ...
  },
);
```

Call `shell.dispose()` when the host tears down.

### 3. One MultiColumnScaffold per tab

Keep tabs alive with `IndexedStack`. Point `onEscapePop` at the **same** navigator instance used for pushes.

```dart
IndexedStack(
  index: shell.currentIndex.value,
  children: [
    MultiColumnScaffold(
      controller: shell.stacks[0],
      root: const HomeTab(),
      rootName: 'Home',
      visibleCount: shell.visibleColumnCount,
      showBreadcrumbs: shell.isExpanded,
      onEscapePop: navigator.pop,
      leftPaneFraction: shell.leftPaneFraction.value,
      onLeftPaneFractionChanged: (v) => shell.leftPaneFraction.value = v,
    ),
    // stacks[1] …
  ],
);
```

Use compact `NavigationBar` vs wide `NavigationRail` from `LayoutBreakpoints.isCompact(width)`. `changePage` only switches tabs.

### 4. Implement AdaptiveNavigatorFallback

**Navigator-only** (see [`example/lib/demo.dart`](example/lib/demo.dart)): `push` / `pushReplacement` on a root `GlobalKey<NavigatorState>`; named methods build the same widget your `buildPage` would build.

**GoRouter** (typical production host):

| Fallback method | GoRouter / Navigator |
| --- | --- |
| `push` / `pushReplacement` | `Navigator.push` / `pushReplacement` with `MaterialPageRoute` |
| `pushNamed` | `context.pushNamed` |
| `pushReplacementNamed` | `context.goNamed` (replace the current location; same as today’s shell “go”) |
| `pushAndRemoveUntil` | `pushReplacement` |
| `pushNamedAndRemoveUntil` | `pushNamed` (keep compact chat as a normal push) |
| `pop` / `canPop` | `context.pop` / `context.canPop` |
| `popToRoot` | `Navigator.popUntil(context, (r) => r.isFirst)` |

### 5. Construct AdaptiveNavigator

```dart
final navigator = AdaptiveNavigator(
  isSlidingActive: () => shell.isSlidingActive,
  currentStack: () => shell.currentStack,
  buildPage: (args) {
    return switch (args.name) {
      '/inbox' => const InboxPage(),
      '/thread/:id' => ThreadPage(id: args.pathParameters['id'] ?? ''),
      _ => null,
    };
  },
  handlesRoute: (name) => name != '/photo' && name != '/login',
  resolveTitle: (name) => localizedTitle(name),
  fallback: const MyGoRouterFallback(),
);
```

`handlesRoute: false` keeps the page on the host navigator even when sliding is active (fullscreen image, auth).

### 6. Route every feature through that navigator

```dart
navigator.pushNamed('/inbox', from: context);
navigator.push(const SettingsPage(), name: '/settings');
navigator.pushReplacementNamed('/replaced');
navigator.pushAndRemoveUntil(const PeerPage(), AdaptiveNavigator.untilRoot);
navigator.pop();
navigator.popToRoot();
```

### 7. Peer replace (chat-style)

The package does not switch tabs. The host does:

```dart
shell.changePage(1); // conversation tab
await navigator.pushNamedAndRemoveUntil(
  '/chat',
  AdaptiveNavigator.untilRoot,
  extra: conversationId,
);
```

### 8. Menus inside a pane

```dart
useRootNavigator: inSlidingWindow(context)
```

## Caveats

- **`PopScope` does not intercept sliding-stack pops.** Pane back uses `LocalHistoryEntry` plus `SlidingActions` / `AdaptiveNavigator.pop`. Wrap host routes if you need compact-only intercept.
- **Pane overlays are clipped.** Dialogs, menus, and sheets inside a column should use the root overlay (`inSlidingWindow`).
- **Root key is fixed.** `ensureRoot` always uses `ValueKey('sliding-root')`. `AdaptiveNavigator.untilRoot` depends on that. Do not replace the root key.
- **Compact keeps the sliding stack at root.** The same taps use the fallback navigator; you can pop Attachment → Reply → … on the host stack while `shell.currentStack.depth` stays `1`.
- **Sash callback is on release.** Do not expect `onLeftPaneFractionChanged` on every pointer move.

## Example

[`example/`](example/) is a host **without** GoRouter: compact bottom bar, wide rail, two tabs (`Home`, `Explore`).

Deep Push Slide chain (every step uses `pushNamed(..., from:)`):

```
Home → Inbox → Thread → Reply → Attachment
  1       2        3        4          5
```

Routes: `/inbox`, `/thread/:id`, `/reply/:id`, `/attachment/:id`.

On a 900-wide window (`visibleCount == 2`) depth 5 shows only **Reply + Attachment**. Home and Inbox stay on the stack. Opening another Attachment from Reply replaces the right pane; `popToRoot` returns to `[Home]`.

On a 400-wide window the same taps use the root `Navigator`. The sliding stack stays `[Home]`; you can pop Attachment → Reply → Thread → Inbox → Home.

Other demo verbs: `push` (Settings), `pushAndRemoveUntil` (Peer), `pushReplacementNamed` (replace top), `/chat` (`pushNamedAndRemoveUntil` + tab switch), `/photo` (`handlesRoute` false).

Resize the window across 600 and 840 to see the three bands. See [example/README.md](example/README.md).

## Tests

```bash
cd package/xue_hua_adaptive_sliding_layout && flutter test
cd package/xue_hua_adaptive_sliding_layout/example && flutter test
```

Package `test/` covers controllers and `AdaptiveNavigator` in isolation. `example/test` drives the three breakpoints, the depth-5 chain, left-pane `openAfter`, and compact fallback pops.
