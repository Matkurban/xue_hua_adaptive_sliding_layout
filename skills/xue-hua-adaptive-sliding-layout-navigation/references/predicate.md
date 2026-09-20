# Route predicate

Source: `lib/src/router/match.dart`.

## `AdaptiveRoutePredicate`

```dart
typedef AdaptiveRoutePredicate = bool Function(AdaptiveRouteMatch match);
```

Predicate for `AdaptiveRouter.popUntil` and `AdaptiveRouter.pushNamedAndRemoveUntil`.

The engine pops while `current.canPop && (current.last == null || !predicate(current.last!))`.

| Typical predicate                     | Effect                                                                                                                      |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `(m) => m.pageKey == pane.key`        | Pop until that pane (breadcrumbs).                                                                                          |
| `(m) => m.matchedLocation == '/mail'` | Pop until that path.                                                                                                        |
| `(_) => false`                        | Pop until `canPop` is false (branch root / single overlay-only root), then `pushNamed` the new location — rebuild from URL. |

`popUntil` does not pop past the branch root: when `canPop` is false the loop stops even if the predicate is still false.
