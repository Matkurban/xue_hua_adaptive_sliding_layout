---
name: xue-hua-adaptive-sliding-layout-navigation
description: >-
  Call xue_hua_adaptive_sliding_layout navigation verbs: pushNamed,
  pushReplacementNamed, pushNamedAndRemoveUntil, popAndPushNamed, pop,
  maybePop, popFrom, maybePopFrom, popUntil, canPop, namedLocation,
  goBranch, and arguments futures. Use when navigating, switching tabs,
  closing a sheet or dialog in a specific pane, confirming exit, or
  replacing go_router context.go / context.push.
license: Apache-2.0
---

# Navigation: Navigator-named verbs

Names and signatures match `NavigatorState`. There is no `push(Route)` — every page must be in the table so the URL can express it. `routeName` is a **location** (`/mail/inbox/42`), not `AdaptiveRoute.name`.

API: [references/verbs.md](references/verbs.md), [references/predicate.md](references/predicate.md).

## Guidelines

- Take the router with `AdaptiveRouter.of(context)` or hold the host instance. There are no `context.go` / `context.pushNamed` / `context.pop` extensions.
- Build a location from a table name with `router.namedLocation('thread', pathParameters: {'folder': 'inbox', 'threadId': '42'}, queryParameters: {'ref': 'push'})`. Unknown name or missing path param throws `ArgumentError`.
- `pushNamed` returns a `Future` completed by `pop(result)` (or dispose) of that **imperative** leaf. URL-derived matches have no completer; the future completes with `null`.
- `arguments` is the opaque object on `AdaptiveRouteState.arguments` (not go_router `extra`).
- Imperative `*Named` verbs run `resolve` first (top-level + per-route redirect) when `navigatorKey.currentContext` is available. If resolve ends in an empty error list, the original `routeName` is used.
- `pop` does **not** call `onExit`. If a dialog, sheet, or menu covers the **top** page (pane, shell, or root navigator — outermost first), `pop` and `maybePop` close that route and leave the page stack. Otherwise `maybePop` asks the top page’s `PopScope` first, then `onExit`. AppBar back, system back, browser back, and Escape use `maybePop`. At the bottom of the stack `maybePop` returns `false` without an exit dialog — that dialog is `popRoute` / a shell `PopScope`.
- `pop` / `maybePop` are context-free and only look at the top pane. To close a sheet or dialog in a **specific** pane (e.g. the left pane after it pushed the right page, or when both panes have one open), use `popFrom(context)` / `maybePopFrom(context)` with a context inside that popup or inside that page. Inside the popup itself, plain `Navigator.pop(context)` also works.
- `pushReplacementNamed`, `pushNamedAndRemoveUntil`, and `popAndPushNamed` run immediately (no `onExit`), like `Navigator`.
- `popUntil` / `pushNamedAndRemoveUntil` never pop the branch root (`canPop` is false there). Predicate `(_) => false` rebuilds from the URL (deep link, login return, reset tab).
- Tab switches are not a Navigator verb. Use `AdaptiveShellState.goBranch(index, {initialLocation})` or `AdaptiveRouter.goBranch`. Tapping the **current** tab with `initialLocation: true` returns to `AdaptiveBranch.initialLocation`.
- `goBranch` back to a visited tab restores the stored stack (`arguments`, `pageKey`, title signal, completer) instead of rematching the URL (3.1.1).
- A location that does not start with `/` is parsed as `'/$routeName'`.

### `pushNamed` stack rules

After redirect and a successful match:

1. **Overlay target** (`fullscreen` / `fullscreenDialog` / off-shell / empty match): append the leaf on the current stack (or replace an empty / error stack with the match). Existing overlays stay under the new leaf.
2. **Other branch**: dispose current overlays and replace the visible stack with the URL-derived target (tab switch).
3. **Same branch, prefix** (`isMatchPrefix`): reuse existing matches for the shared prefix; extend with the new suffix. Example: `/mail` → `/mail/inbox/42` slides in two panes.
4. **Same branch, not a prefix**: keep the current branch stack and **append the target leaf**. Example: `/mail/inbox/41` → `/mail/inbox/42` yields `[mail, inbox, 41, 42]`. Completes the previous leaf only when it is actually popped later.

Same-branch navigation disposes current overlays first.

## Examples

### From a page

```dart
final router = AdaptiveRouter.of(context);
router.pushNamed('/mail/inbox');
router.pushNamed(
  router.namedLocation('thread', pathParameters: {
    'folder': 'inbox',
    'threadId': '42',
  }),
  arguments: thread,
);
router.pop();
```

### Await a result

```dart
final saved = await router.pushNamed<bool>('/contacts/new');
// In the form page:
router.pop(true);
```

### Replace the top (folder swap, login ↔ register)

```dart
router.pushReplacementNamed('/mail/sent');
router.pushReplacementNamed('/register');
```

### Rebuild the stack from a URL (login return, `context.go`)

```dart
final from = state.queryParameters['from'] ?? '/mail';
router.pushNamedAndRemoveUntil(from, (_) => false);
```

### Breadcrumb pop

```dart
router.popUntil((match) => match.pageKey == pane.key);
```

### Tab switch

```dart
void onDestinationSelected(int index) {
  if (index == shell.currentIndex) {
    shell.goBranch(index, initialLocation: true); // back to branch root
    return;
  }
  shell.goBranch(index);
}
```

### `maybePop` vs `pop`

```dart
// AppBar / system back / Escape — honors PopScope + onExit
await router.maybePop();

// Imperative dismiss — skips onExit
router.pop(result);
```

### Close the sheet that opened the right pane

```dart
// Inside a sheet shown from the left pane (useRootNavigator: false):
onTap: () {
  final router = AdaptiveRouter.of(context);
  router.pushNamed('/contacts/42');   // opens the right pane
  router.maybePopFrom(context);       // closes this sheet, not the new page
}

// From the page below the sheet, or with a sheet open in each pane:
router.maybePopFrom(pageContext);     // closes the popup covering that page only
```

### No-context host call

```dart
// The same AdaptiveRouter instance given to MaterialApp.router:
appRouter.pushNamed('/playground');
```
