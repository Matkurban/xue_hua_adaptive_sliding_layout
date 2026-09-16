# xue_hua_adaptive_sliding_layout

[English](README.md) · **[在线 Demo](https://matkurban.github.io/xue_hua_adaptive_sliding_layout/)**

面向 Flutter 的声明式自适应路由。**一张路由表**把 URL 映射成页面栈，再按窗口宽度摆成 1 栏 `Navigator` 或 2 栏滑动视口。调用方式与 `Navigator` 相同：`AdaptiveRouter.of(context).pushNamed(...)`。

**不依赖** `go_router`。宿主自己持有 `AdaptiveRouter` 实例，无需服务定位器。额外依赖：`signals_flutter`、`material_ui`。

- [60 秒快速开始](#60-秒快速开始)
- [URL → 栈 → 栏位](#url--栈--栏位)
- [路由表](#路由表)
- [导航动词](#导航动词)
- [读取状态](#读取状态)
- [自定义 UI](#自定义-ui)
- [不用路由只要布局](#不用路由只要布局)
- [示例场景](#示例场景)
- [从 2.x 迁移](#从-2x-迁移)
- [从 go_router 迁移](#从-go_router-迁移)
- [注意点](#注意点)

## 60 秒快速开始

```dart
final router = AdaptiveRouter(
  initialLocation: '/mail',
  routes: [
    AdaptiveShellRoute(
      builder: (context, shell, child) {
        return Scaffold(
          body: child,
          bottomNavigationBar: shell.isCompact
              ? NavigationBar(
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: (i) => shell.goBranch(i),
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.mail), label: 'Mail'),
                    NavigationDestination(icon: Icon(Icons.people), label: 'Contacts'),
                  ],
                )
              : null,
        );
      },
      branches: [
        AdaptiveBranch(routes: [
          AdaptiveRoute(
            path: '/mail',
            title: (_) => 'Mail',
            builder: (context, state) => const MailPage(),
            routes: [
              AdaptiveRoute(
                path: ':folder',
                builder: (context, state) =>
                    FolderPage(folder: state.pathParameters['folder']!),
              ),
            ],
          ),
        ]),
        AdaptiveBranch(routes: [
          AdaptiveRoute(
            path: '/contacts',
            builder: (context, state) => const ContactsPage(),
          ),
        ]),
      ],
    ),
  ],
);

MaterialApp.router(routerConfig: router);
```

页面里：

```dart
final router = AdaptiveRouter.of(context);
router.pushNamed('/mail/inbox');
router.pushNamed(
  router.namedLocation('thread', pathParameters: {'folder': 'inbox', 'threadId': '42'}),
  arguments: thread,
);
router.pop();
```

完整路由表可直接照抄 [`example/lib/router.dart`](example/lib/router.dart)。

## URL → 栈 → 栏位

```mermaid
flowchart LR
  URL["URL  /mail/inbox/42/reply"] --> Parser["RouteInformationParser"]
  Parser --> Matches["MatchList  mail, inbox, 42, reply"]
  Matches --> Delegate["RouterDelegate"]
  Delegate --> Shell["AdaptiveShellRoute.builder"]
  Shell --> Width{"窗口宽度"}
  Width -->|"< 840  1 栏"| Nav["Navigator pages"]
  Width -->|">= 840  2 栏"| Panes["SlidingPaneViewport 最后 2 栏"]
  Delegate --> Overlay["fullscreen / 壳外路由"]
```

`/mail/inbox/42/reply` 沿路由树匹配出一串 match，这一串就是页面栈。低于 `expandedMinWidth`（默认 840）时走经典 `Navigator`；达到该宽度时，最后两层并排显示在 [`SlidingPaneViewport`](lib/src/layout/sliding_pane_viewport.dart)，更深的页把旧栏推向左侧。`fullscreen: true` 与 `fullscreenDialog: true` 的匹配叠在**根** Navigator（登录、照片、撰写对话框）。

浏览器后退、深链、刷新都只是换了一个 location，走同一条路径。Web 使用默认 **hash** 策略（`/#/mail/inbox/42`），GitHub Pages 不需要 404 回退。

## 路由表

| 类型 | 职责 |
| --- | --- |
| [`AdaptiveRouter`](lib/src/router/adaptive_router.dart) | `RouterConfig<AdaptiveRouteMatchList>`。动词 + `namedLocation` / `refresh`。只读 signal：`location`、`matches`、`currentBranch`。`of` / `maybeOf`。 |
| [`AdaptiveRoute`](lib/src/router/route.dart) | 一页。`path`、可选 `name`、`builder`、`title`、`fullscreen`、`fullscreenDialog`、`opaque`、`barrierColor`、`barrierDismissible`、`transitionsBuilder`、`redirect`、`onExit`、子 `routes`。子路径为相对路径，`:param` 与 go_router 相同。顺序优先匹配。 |
| [`AdaptiveShellRoute`](lib/src/router/route.dart) | Tab + 自适应壳。整棵树只允许一个，且必须顶层。`builder(context, shell, child)`、`branches`、`breakpoints`、分割条 / 面包屑，以及 [UI 属性](#自定义-ui)。 |
| [`AdaptiveBranch`](lib/src/router/route.dart) | 一个 Tab。`routes`，可选 `initialLocation` / `placeholder`。 |
| [`AdaptiveRouteState`](lib/src/router/route_state.dart) | builder 参数，也可 `AdaptiveRouteState.of(context)`：`uri`、`matchedLocation`、`fullPath`、`name`、`pathParameters`、`queryParameters`、`arguments`、`error`、`pageKey`。 |
| [`AdaptiveShellState`](lib/src/router/route_state.dart) | 壳 builder 参数：`currentIndex`、宽度 / 断点、`leftPaneFraction`、`goBranch`。 |
| [`LayoutBreakpoints`](lib/src/layout/layout_breakpoints.dart) | `const` 类，默认 `compactMaxWidth: 600`、`expandedMinWidth: 840`。 |

用 `builder + transitionsBuilder` 取代 go_router 的 `pageBuilder`，因为宽屏栏位需要的是 Widget，不是 Page。

顶层 `redirect` 与路由级 `redirect` 可返回新 location（`FutureOr<String?>`）。跳数超过 `redirectLimit`（5）视为循环，走 `errorBuilder`。

## 导航动词

名称和签名与 [`NavigatorState`](https://api.flutter.dev/flutter/widgets/NavigatorState-class.html) 一致。`routeName` 就是 location。不提供非 Named 的 `push(Route)`：所有页面必须在路由表中，否则 URL 无法表达。

| 调用 | 窄屏（1 栏） | 宽屏（2 栏） |
| --- | --- | --- |
| `pushNamed` | 压入分支 `Navigator`；`fullscreen` / 壳外则叠到根上。同分支且当前栈是目标前缀时补齐尾部（`/mail` → `/mail/inbox/42` 可一次滑入两栏）。同分支非前缀则把叶子压到栈顶（`/mail/inbox/41` → `/mail/inbox/42` 得到 `[mail, inbox, 41, 42]`）。其他分支：切 Tab 并按 URL 重建该分支栈。 |
| `pushReplacementNamed` | 只换栈顶。同级替换，右栏原地换内容。 |
| `pushNamedAndRemoveUntil` | 先弹到 predicate 为 true 再 `pushNamed`。`(_) => false` 按 URL 重建（深链、登录回跳、Tab 回根）。 |
| `popAndPushNamed` | 先 `pop` 再 `pushNamed`。 |
| `pop` | 立刻弹出。**不问** `onExit`。 |
| `maybePop` | 询问栈顶 `onExit`。AppBar 返回、系统返回、浏览器后退、Escape 都走它。 |
| `popUntil` | 弹到 predicate 为 true，不超过分支根。 |
| `canPop` | 有覆盖层，或当前分支深度 > 1。 |

Tab 切换不是 Navigator 动词，用 `AdaptiveShellState.goBranch(index, {initialLocation})`。内部等价于按该分支上次位置（或 `initialLocation`）做 `pushNamedAndRemoveUntil`。点**当前** Tab 并传 `initialLocation: true` 回到分支根，见 [`example/lib/shell/app_shell.dart`](example/lib/shell/app_shell.dart)。

辅助：`namedLocation` 把路由名 + 参数拼成 location；`refresh()` 在登录态变化后重跑 redirect。

`pushNamed` 返回的 `Future` 由 `pop(result)` 完成。

## 读取状态

```dart
AdaptiveRouter.of(context).location.value;          // '/mail/inbox/42'
AdaptiveRouteState.of(context).pathParameters;
AdaptivePaneScope.maybeOf(context)?.title.value = subject;
AdaptiveShellScope.maybeOf(context)?.isExpanded;
```

[`AdaptivePaneScope.maybeOf`](lib/src/layout/pane_scope.dart) 仅在双栏栏位内非 null，用来替代 2.x 的 `inSlidingWindow` / `SlidingPageTitle`。异步标题：拿到 subject 后写 `title.value` 即可，包不再遍历 Element 树刮 `AppBar.title`。

UI 订阅用 `SignalBuilder`（见 `signals_flutter`）。

想在**自己的**壳里画标题而不是内置条带，读 `AdaptiveRouter.of(context).matches.value.branchMatches`（每个 match 有 `title` signal 和 `name`）。

## 自定义 UI

用 **builder** 换结构，用 **值参数** 换数值。默认行为与 3.0 首次发布一致。主题色仍从 `Theme.of(context)` 取。1 栏过场走 Flutter 的 `ThemeData.pageTransitionsTheme`。

### 视口（`SlidingPaneViewport` / `AdaptiveShellRoute`）

| 参数 | 默认 | 作用 |
| --- | --- | --- |
| `slideDuration` | 280ms | 栏位平移 |
| `slideCurve` | `Curves.easeOutCubic` | 栏位平移 |
| `paneBuilder` | 双栏卡片 / 单栏平铺 | 包每一栏。`index == panes.length` 是右侧空槽 |
| `resizeHandleBuilder` | 2px `outline` 线 | 只换视觉；命中区仍是 44px |
| `placeholder` | outline 图标 | 壳级右栏空态；`AdaptiveBranch.placeholder` 优先 |

### 面包屑

| 参数 | 默认 | 作用 |
| --- | --- | --- |
| `height` | 36 | 条带高度 |
| `padding` | 水平 12 | 条带内边距 |
| `backgroundColor` | `surfaceContainerLow` | 条带底色 |
| `itemBuilder` | InkWell + Text | 单个面包屑 |
| `separatorBuilder` | chevron | 分隔符 |
| `AdaptiveShellRoute.breadcrumbsBuilder` | `AdaptiveBreadcrumbs` | 整条替换（仍受 `showBreadcrumbs` 控制） |
| `escapePops` | true | Escape 调用 `maybePop` |

嵌套页保留宿主 chrome（同 go_router `ShellRoute`）。要盖住底栏，用 `fullscreen` 或 `fullscreenDialog`。

### 覆盖层（`AdaptiveRoute`）

| 参数 | 默认 | 作用 |
| --- | --- | --- |
| `fullscreenDialog` | false | 根 Navigator 全屏对话框，盖住壳 / 底栏（= go_router `parentNavigatorKey: rootNavigatorKey`） |
| `opaque` | true | 配合 `transitionsBuilder`：透明照片查看器 |
| `barrierColor` | null | 配合 `transitionsBuilder` |
| `barrierDismissible` | false | 点屏障弹出 |

完整例子见 [`example/lib/router.dart`](example/lib/router.dart)：卡片 / 平铺 `paneBuilder`、40px 面包屑、半透明 `/photo/:id`。

## 不用路由只要布局

[`SlidingPaneViewport`](lib/src/layout/sliding_pane_viewport.dart)、[`SlidingPane`](lib/src/layout/pane_scope.dart)、[`AdaptiveBreadcrumbs`](lib/src/layout/breadcrumbs.dart) 保持公开，只想要滑动栏时可以直接用。

断点只看窗口宽度，不看设备类型：

| 宽度 | 分档 | 可见栏 |
| --- | --- | --- |
| `< compactMaxWidth`（600） | compact | 1 — `Navigator` 全屏栈 |
| `600–839` | medium | 1 — 同样是 `Navigator`；宿主用 `shell.isMedium` 区分 chrome |
| `≥ expandedMinWidth`（840） | expanded | 2 — 最后两栏 + 可选分割条 |

`ponytail:` 视口只支持 1 / 2 栏。三栏及以上需要改 `visibleColumnCount` 并让视口按 N 栏布局。

## 示例场景

[`example/`](example/) 是接入模板。网页 Demo 顶部有 Phone 412 / Foldable 700 / Tablet 1024 / Desktop 宽度预设，不用缩放窗口。

| 区域 | 演示内容 | 文件 |
| --- | --- | --- |
| Mail | 4 层深栈、分割条、面包屑 `popUntil`、换文件夹 `pushReplacementNamed`、`pushNamed` 滑入 vs 压栈顶、异步栏标题、`arguments` + `?ref=`、回复 keep-alive、全屏照片 | [`features/mail`](example/lib/features/mail/mail_pages.dart) |
| Contacts | `?q=` 即 URL 状态、`namedLocation`、`await pushNamed<bool>` + `pop(true)`、`onExit`（`maybePop` vs `pop`）、头像 → 照片 | [`features/contacts`](example/lib/features/contacts/contact_pages.dart) |
| Settings | `redirect` 到 `/login?from=`、登录后 `pushNamedAndRemoveUntil` 回跳、登出 `refresh()`、主题 / 分割比例、`errorBuilder` 404 | [`features/settings`](example/lib/features/settings/settings_pages.dart) |
| Playground | 每个 Navigator 动词、无 context 的 `router.pushNamed`、自定义过场、对话框 / 底部弹层 `useRootNavigator` 对比、Escape | [`features/playground`](example/lib/features/playground/playground_page.dart) |
| 壳 / 外框 | compact `NavigationBar` vs rail、宽度预设 | [`app_shell.dart`](example/lib/shell/app_shell.dart)、[`demo_frame.dart`](example/lib/frame/demo_frame.dart) |

```bash
cd example && flutter run -d chrome
cd example && flutter test
```

## 从 2.x 迁移

| 2.x | 3.x |
| --- | --- |
| `SlidingShell` + 每 Tab `MultiColumnScaffold` + `AdaptiveNavigator` + 9 个 fallback 方法 | 一个 `AdaptiveRouter` + `MaterialApp.router` |
| `handlesRoute` / `buildPage` / `resolveTitle` | 路由表里的 `AdaptiveRoute` |
| `from:` / `openAfter` / `openSecondary` | URL 即栈（`pushNamed` 前缀补齐 vs 压叶子） |
| `extra` | `arguments` |
| `inSlidingWindow(context)` | `AdaptivePaneScope.maybeOf(context) != null` |
| `SlidingPageTitle.report` | `AdaptivePaneScope.maybeOf(context)?.title.value = …` |
| `SlidingActions.pop` | `AdaptiveRouter.of(context).maybePop()` |

没有兼容层。详见 [CHANGELOG](CHANGELOG.md)。

## 从 go_router 迁移

| go_router | 本包 |
| --- | --- |
| `GoRoute` | `AdaptiveRoute` |
| `StatefulShellRoute.indexedStack` | `AdaptiveShellRoute` + `AdaptiveBranch` |
| `context.go(loc)` | `router.pushNamedAndRemoveUntil(loc, (_) => false)` |
| `context.push(loc)` | `router.pushNamed(loc)` |
| `extra` | `arguments` |
| `GoRouterState` | `AdaptiveRouteState` |
| `pageBuilder` | `builder` + 可选 `transitionsBuilder` |
| `context.go` / `context.pop` 扩展 | 只用 `AdaptiveRouter.of(context)` |

## 注意点

- 跨越 840 断点会**重建**页面 `State`（Navigator 树 ↔ 视口树）。持久状态放进 URL、signal 或宿主存储。
- 栏内 Overlay 会被裁剪。对话框、菜单、底部弹层请走根 Overlay：`useRootNavigator: AdaptivePaneScope.maybeOf(context) != null`。
- `onExit` 只在 `maybePop`、系统返回、浏览器后退时询问。`pop` / `pushReplacementNamed` / `pushNamedAndRemoveUntil` 与 Navigator 一样直接执行。
- Web 保持 hash URL。平台带了非 `/` 的初始路由时，优先于 `initialLocation`。
- 整棵树只允许一个顶层 `AdaptiveShellRoute`。不做嵌套壳、`restorable*`、`context.pushNamed` 扩展。

## 测试

```bash
flutter analyze && flutter test
cd example && flutter analyze && flutter test
```
