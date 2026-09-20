# Router scope

Source: `lib/src/router/adaptive_router.dart`.

## `AdaptiveRouterScope`

`InheritedWidget` that exposes the host `AdaptiveRouter` to the subtree. Inserted by the router delegate. Host apps construct this only if they embed the router widgets themselves; `MaterialApp.router(routerConfig: router)` already provides it.

## Constructor

```dart
const AdaptiveRouterScope({
  super.key,
  required AdaptiveRouter router,
  required super.child,
})
```

## Fields

### `router`

```dart
final AdaptiveRouter router;
```

The application’s single router instance.

## `updateShouldNotify`

```dart
@override
bool updateShouldNotify(AdaptiveRouterScope oldWidget) =>
    router != oldWidget.router;
```

Dependents (`AdaptiveRouter.of` / `maybeOf`) rebuild only when the **instance** changes, not when `location` / `matches` change. Those are `Signal`s — subscribe with `SignalBuilder`.
