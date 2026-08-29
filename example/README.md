# Example

Host demo for [`xue_hua_adaptive_sliding_layout`](../README.md) ([中文](../README.zh-CN.md)). No GoRouter: compact bottom bar, wide rail, two tabs, and a Push Slide chain

`Home → Inbox → Thread → Reply → Attachment`.

This app is the **Navigator-only** integration described in the package README:

- English: [Integrate in a real project](../README.md#integrate-in-a-real-project) and [Example](../README.md#example)
- 中文：[真实项目接入](../README.zh-CN.md#真实项目接入) 与 [示例](../README.zh-CN.md#示例)

Wiring lives in [`lib/demo.dart`](lib/demo.dart) (`SlidingShell` + `AdaptiveNavigator` + `DemoNavigatorFallback`) and [`lib/main.dart`](lib/main.dart) (`LayoutBuilder` → `updateViewportWidth`, `IndexedStack` of `MultiColumnScaffold`).

Resize the window across **600** (compact → medium, sliding turns on) and **840** (medium → expanded, two columns) to see the three breakpoint bands.

```bash
flutter run
flutter test
```
