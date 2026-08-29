# xue_hua_adaptive_sliding_layout

[English](README.md)

面向 Flutter 的自适应移动端 / 桌面端多栏滑动布局。路由、依赖注入、文案翻译由宿主负责；本包只负责 **断点**、**每 Tab 的滑动栈**、**视口**，以及可选的 **命名路由拦截**。

**不依赖** `go_router`、GetIt、任何 l10n 包。额外依赖只有 `signals_flutter`。

- [解决什么问题](#解决什么问题)
- [组件一览](#组件一览)
- [断点与可见栏](#断点与可见栏)
- [各部分如何连起来](#各部分如何连起来)
- [按类写 API](#按类写-api)
  - [LayoutBreakpoints](#layoutbreakpoints)
  - [SlidingShell](#slidingshell)
  - [SlidingWindowController](#slidingwindowcontroller)
  - [SlidingWindowPage](#slidingwindowpage)
  - [AdaptiveNavigator](#adaptivenavigator)
  - [AdaptiveNavigatorFallback](#adaptivenavigatorfallback)
  - [AdaptiveRouteArgs](#adaptiverouteargs)
  - [MultiColumnScaffold](#multicolumnscaffold)
  - [SlidingWindowViewport](#slidingwindowviewport)
  - [SlidingActions 与 SlidingBackButton](#slidingactions-与-slidingbackbutton)
  - [SlidingPageTitle](#slidingpagetitle)
  - [SlidingWindowScope / SlidingPaneScope / inSlidingWindow](#slidingwindowscope--slidingpanescope--inslidingwindow)
- [真实项目接入](#真实项目接入)
- [注意点](#注意点)
- [示例](#示例)
- [测试](#测试)

## 解决什么问题

窄屏上，页面仍走宿主的 `Navigator` / GoRouter。

达到中屏宽度后，被拦截的页面**离开**根导航，进入当前 Tab 的滑动栈。宽屏并排显示栈顶两页；再深的页面把更早的页推向左侧，而不是再开第三栏。

典型接入：

1. 每个 Tab 一个 [`SlidingWindowController`](lib/src/sliding_window_controller.dart)，或用 [`SlidingShell`](lib/src/sliding_shell.dart) 统一创建。
2. 每个 Tab 包一层 [`MultiColumnScaffold`](lib/src/multi_column_scaffold.dart)。
3. 所有跳转走 [`AdaptiveNavigator`](lib/src/adaptive_navigator.dart)：写入滑动栈，或调用宿主的 [`AdaptiveNavigatorFallback`](lib/src/adaptive_navigator.dart)。

## 组件一览

| 类型 | 职责 | 谁创建 | 谁消费 |
| --- | --- | --- | --- |
| [`LayoutBreakpoints`](lib/src/layout_breakpoints.dart)（`AppBreakpoints`） | 按窗口宽度分 compact / medium / expanded | 无（静态） | 宿主布局 + `SlidingShell` |
| [`SlidingShell`](lib/src/sliding_shell.dart) | 每 Tab 一个栈、视口宽度、共用左栏比例 | 宿主，一次 | 宿主布局 + `AdaptiveNavigator` |
| [`SlidingWindowController`](lib/src/sliding_window_controller.dart) | 单个 Tab 的页面栈 | `SlidingShell.init` 或宿主 | 视口 + 导航 |
| [`SlidingWindowPage`](lib/src/sliding_window_page.dart) | 栈里的一页（key、name、title、builder、completer） | controller | 视口、面包屑 |
| [`MultiColumnScaffold`](lib/src/multi_column_scaffold.dart) | Tab 壳：可选侧栏、面包屑、Escape、视口 | 宿主每个 Tab | 用户 |
| [`SlidingWindowViewport`](lib/src/sliding_window_viewport.dart) | 画出最后 1～2 栏；可选分割条 | `MultiColumnScaffold` | 用户 |
| [`AdaptiveNavigator`](lib/src/adaptive_navigator.dart) | 与 Navigator 成对的动词；宽屏栈或 fallback | 宿主，一次 | 每一次跳转 |
| [`AdaptiveNavigatorFallback`](lib/src/adaptive_navigator.dart) | 窄屏 / 未拦截的命名路由 | 宿主实现 | `AdaptiveNavigator` |
| [`AdaptiveRouteArgs`](lib/src/adaptive_navigator.dart) | 给 `buildPage` 的 name + extra + path/query | navigator | 宿主页面工厂 |
| [`SlidingActions`](lib/src/sliding_actions.dart) | 向子树注入 `pop`（AppBar / Escape / 返回钮） | `MultiColumnScaffold` | 视口 + `SlidingBackButton` |
| [`SlidingBackButton`](lib/src/sliding_back_button.dart) | 只在最右非根栏显示的返回 | 宿主页面 | 用户 |
| [`SlidingPageTitle`](lib/src/sliding_page_title.dart) | 面包屑标题；`report` / `humanize` | 视口 | 宿主页面 |
| [`SlidingWindowScope`](lib/src/sliding_window_scope.dart) | 暴露当前 Tab 的 controller | `MultiColumnScaffold` | 菜单 / 自定义 pop |
| [`SlidingPaneScope`](lib/src/sliding_window_scope.dart) | 栏位下标 + `showBack` | 视口 | `from:` 压栈、返回钮 |
| [`inSlidingWindow`](lib/src/sliding_window_scope.dart) | 在滑动视口内为 `true` | — | 菜单 / Overlay 宿主 |

## 断点与可见栏

[`LayoutBreakpoints`](lib/src/layout_breakpoints.dart) 按**窗口宽度**判断，不按设备类型或方向。

| 宽度 | 档位 | 可见栏数 | 滑动栈 |
| --- | --- | --- | --- |
| `< 600` | compact | 1 | **关闭** — 走宿主导航 |
| `600–839` | medium | 1 | **开启** — 只看见一栏 |
| `≥ 840` | expanded | 2 | **开启** — 看见最后两栏 |

[`SlidingShell.isSlidingActive`](lib/src/sliding_shell.dart) 在 `init()` 之后、宽度**不是** compact 时为 `true`。[`AdaptiveNavigator`](lib/src/adaptive_navigator.dart) 用这个标志决定拦截还是回落。

`visibleColumnCount` 只在 expanded 为 `2`，否则为 `1`。**栈深度可以大于可见栏数**。深度 5 时视口可以只显示 Reply + Attachment，Home / Inbox 仍留在栈里。

## 各部分如何连起来

```
宿主应用
  ├─ SlidingShell          各 Tab 栈 + 宽度 + leftPaneFraction
  ├─ AdaptiveNavigator     动词 → 滑动栈或 fallback
  │    └─ Fallback         窄屏 / handlesRoute == false
  └─ 每 Tab：MultiColumnScaffold
       ├─ SlidingWindowScope / SlidingActions
       └─ SlidingWindowViewport → SlidingWindowController.pages
```

宽屏且 `handlesRoute(name)` 为 true：写入当前 Tab 栈。窄屏，或宿主拒绝的名字：走 fallback。Controller 上的 `push` / `openAfter` / `replace` 是实现细节；日常跳转应走 `AdaptiveNavigator`。

## 按类写 API

### LayoutBreakpoints

密封工具类。别名：`typedef AppBreakpoints = LayoutBreakpoints`。

| 成员 | 含义 |
| --- | --- |
| `compactMaxWidth`（`600`） | 低于此宽度为 compact。 |
| `expandedMinWidth`（`840`） | 达到此宽度为 expanded（双栏）。 |
| `isCompact(width)` | `width < 600` |
| `isExpanded(width)` | `width >= 840` |
| `visibleColumnCount(width)` | expanded 为 `2`，否则 `1` |

medium = 非 compact 且非 expanded：滑动栈开着，只显示一栏。

### SlidingShell

每个 Tab 一个 [`SlidingWindowController`](lib/src/sliding_window_controller.dart)，外加共用的视口信号。

```dart
final shell = SlidingShell(tabCount: 2)..init();
// LayoutBuilder 里：
shell.updateViewportWidth(width);
```

| 成员 | 作用 |
| --- | --- |
| `tabCount` | `init()` 会创建几个 controller。 |
| `init()` | 分配 `stacks`。读栈或 `isSlidingActive` 之前必须先调用。 |
| `dispose()` | 完成未决 Future、销毁各栈、标记未初始化。 |
| `updateViewportWidth(width)` | 宽度变化时写入 `viewportWidth`。从 `LayoutBuilder` 驱动。 |
| `changePage(index)` | 设置 `currentIndex`（不会 pop 各栈）。 |
| `stacks` | `init` 之后的 `List<SlidingWindowController>`。 |
| `currentStack` | `stacks[currentIndex]`。 |
| `currentIndex` | `Signal<int>`，默认 `0`。 |
| `viewportWidth` | `Signal<double>`，默认 `0`。 |
| `leftPaneFraction` | 各 Tab 共用的左栏比例，默认 `0.5`。 |
| `isInitialized` | 是否已 `init()`。 |
| `isCompact` / `isExpanded` | 由当前 `viewportWidth` 算出。 |
| `isSlidingActive` | `isInitialized && !isCompact`。 |
| `visibleColumnCount` | 当前宽度下是 `1` 还是 `2`。 |

也可以自己创建 controller，把匹配的 `isSlidingActive` / `currentStack` 闭包传给 `AdaptiveNavigator`。

### SlidingWindowController

**一个** Tab 的栈。根页不可弹出。宿主日常应调 `AdaptiveNavigator`，而不是这些方法。

| 成员 | 作用 |
| --- | --- |
| `pages` | `Signal<List<SlidingWindowPage>>`。 |
| `canPop` | `depth > 1`。 |
| `depth` | `pages.length`。 |
| `indexOfName(name)` | 从后往前找同名非空页，找不到为 `-1`。 |
| `visiblePages(visibleCount)` | 视口应展示的栈顶切片。 |
| `ensureRoot(...)` | 栈空时压入根页（`ValueKey('sliding-root')`）；已有内容则忽略。 |
| `push` | 嵌套压栈（Push Slide），深度 +1。 |
| `openAfter(keepCount, ...)` | 保留前 `keepCount` 页，丢掉后面的，再压入。`keepCount >= 深度` 或栈空时等同 `push`。`keepCount` 至少为 `1`。 |
| `openSecondary` | `openAfter(1, ...)`，栈变为 `[根, page]`。 |
| `replace` | **只换栈顶**（含根）。不会清掉中间层。 |
| `pop([result])` | 弹出栈顶并完成其 Future。在根上返回 `false`。 |
| `popToRoot()` | 一直弹到只剩根页。 |
| `popUntil(predicate)` | 栈顶不满足谓词就继续弹。 |
| `dispose()` | 完成残留 Future、清空 `pages`、销毁 signal。 |

### SlidingWindowPage

栈里的一页。

| 字段 | 作用 |
| --- | --- |
| `key` | 视口保活与 `PageStorageKey`。根页是 `ValueKey('sliding-root')`。 |
| `name` | 路由 id（path 或类型名）。空名在面包屑里可被跳过。 |
| `title` | 面包屑用的 `Signal<String>`，用 `SlidingPageTitle.report` 更新。 |
| `builder` | 构建栏内子树。 |
| `completer` | 该页被弹出或替换时完成。 |
| `dispose()` | 销毁 `title`。 |

### AdaptiveNavigator

宽屏导航。动词与 Flutter `Navigator` 成对：有 `push` 必有 `pushNamed`。

```dart
final navigator = AdaptiveNavigator(
  isSlidingActive: () => shell.isSlidingActive,
  currentStack: () => shell.currentStack,
  buildPage: (args) => /* 按 args.name 构图，或 null */,
  handlesRoute: (name) => name != '/photo',
  resolveTitle: (name) => /* 面包屑标题 */,
  fallback: MyNavigatorFallback(),
);
```

| 构造参数 | 作用 |
| --- | --- |
| `isSlidingActive` | 为 `false` 时一律走 `fallback`。 |
| `currentStack` | 写入哪一个 Tab 的栈。 |
| `buildPage` | 把 [`AdaptiveRouteArgs`](lib/src/adaptive_navigator.dart) 映射成 Widget。`null` → fallback。 |
| `handlesRoute` | 仅宽屏：`false` 则不进滑动栈（全屏大图、登录等）。 |
| `fallback` | 窄屏和未拦截的名字。 |
| `resolveTitle` | 面包屑 / 页面初始标题。缺省 [`SlidingPageTitle.humanize`](lib/src/sliding_page_title.dart)。 |

| 调用 | 宽屏且由本包处理 | 其他情况 |
| --- | --- | --- |
| `push` / `pushNamed`（无 `from`） | 栈顶再压一页 | `fallback.push` / `pushNamed` |
| `push` / `pushNamed`（`from: context`） | 按栏 `openAfter` | 同上 fallback |
| `pushReplacement` / `pushReplacementNamed` | **只换栈顶** | `fallback.pushReplacement*` |
| `pushAndRemoveUntil` / `pushNamedAndRemoveUntil` | 先 `popUntil` 再压入（`untilRoot` → `[根, page]`） | `fallback.pushAndRemoveUntil*` |
| `pop` / `canPop` | 滑动栈还能弹则弹滑动栈 | fallback |
| `popToRoot` | 滑动栈弹到根 | `fallback.popToRoot` |

`from:` **只**出现在 `push` / `pushNamed`，表示「从哪一栏压」，不是 Flutter `Navigator` 的参数。

`push` / `pushNamed` + `from` 的规则：

1. `keepCount = fromPaneIndex + 1`。
2. 若同名非空 `name` 已在 `existing >= keepCount`，则 **跳回** `openAfter(existing)`。
3. 否则 `openAfter(keepCount)`，新页紧挨你点击的那一栏。

没有 `from` 就是普通 `push`。

`AdaptiveNavigator.untilRoot` 为 `page.key == AdaptiveNavigator.rootPageKey`（`ValueKey('sliding-root')`）。同级替换这样写：

```dart
shell.changePage(chatTabIndex);
navigator.pushNamedAndRemoveUntil('/chat', AdaptiveNavigator.untilRoot);
```

切 Tab + 同级替换是**宿主策略**，不是包内回调。

### AdaptiveNavigatorFallback

用现有路由实现。窄屏，以及 `handlesRoute` 为 `false` 的名字，一律走这些方法。

| 方法 | 宿主通常接到 |
| --- | --- |
| `push` / `pushReplacement` | `Navigator.push` / `pushReplacement`（`MaterialPageRoute`） |
| `pushNamed` | `context.pushNamed`（GoRouter），或自己 `push` 一页 |
| `pushReplacementNamed` | GoRouter：`context.goNamed`（换掉当前 location）。纯 `Navigator`：`pushReplacement` |
| `pushAndRemoveUntil` | 窄屏常映射成 `pushReplacement`（没有滑动栈） |
| `pushNamedAndRemoveUntil` | 常映射成 `pushNamed` 或 `pushReplacementNamed` |
| `pop` / `canPop` | 根 Navigator / GoRouter |
| `popToRoot` | `Navigator.popUntil(..., (r) => r.isFirst)` |

窄屏 `Navigator` 上滑动栈的 `predicate` 没有意义。把 `pushAndRemoveUntil` 做成 `pushReplacement` 是常见的 compact 替代。

### AdaptiveRouteArgs

传给 `buildPage`。

| 字段 | 作用 |
| --- | --- |
| `name` | 宿主登记的路由 id（`/thread/:id`、`chat` 等）。 |
| `extra` | `pushNamed(..., extra:)` 带来的不透明对象。 |
| `pathParameters` | 例如 `{'id': '12'}`。 |
| `queryParameters` | 已转成字符串的 query（`dynamic` 会 `toString()`）。 |

### MultiColumnScaffold

每个 Tab 的壳：可选左侧栏、面包屑、Escape、视口。首次 build 会 `controller.ensureRoot`。

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

| 参数 | 作用 |
| --- | --- |
| `controller` | 这个 Tab 的栈。 |
| `root` / `rootName` | 根页 Widget 及其栈内名字。首次 build 调用 `ensureRoot`。 |
| `visibleCount` | 视口显示几栏（`1` 或 `2`）。 |
| `leading` | 可选左侧装饰（列表、Rail 内嵌等）。 |
| `showBreadcrumbs` | 画出**整栈**（不只是可见栏）。点击非最后一项会 `popUntil` 到该页。 |
| `onEscapePop` | 未聚焦输入框时按 Escape 的出栈。同时写入 [`SlidingActions`](lib/src/sliding_actions.dart)，供栏内 AppBar 和 [`SlidingBackButton`](lib/src/sliding_back_button.dart) 使用。缺省 `controller.pop`。建议设为 `AdaptiveNavigator.pop`，让窄屏和宽屏共用一个出栈动词。 |
| `leftPaneFraction` | 双栏时左栏占视口宽度的比例。默认 `0.5`。 |
| `minLeftPaneFraction` / `minRightPaneFraction` | 夹住两栏，避免被拖没。默认 `0.3`（30%–70%）。 |
| `onLeftPaneFractionChanged` | **松手**时回调，拖拽过程中不通知宿主。不传则由视口自己保存比例。 |
| `resizeLeftPane` | 是否显示分割条。缺省在 `visibleCount == 2` 时开启。`false` 锁死分割。 |

单栏和窄屏没有分割条。

### SlidingWindowViewport

通常通过 `MultiColumnScaffold` 使用。分割条参数同上，另外：

| 参数 | 作用 |
| --- | --- |
| `placeholder` | `visibleCount == 2` 且深度为 1 时，空右栏的占位。 |
| `resizeHandleKey` / `visibleLeftPaneKey` / `visibleRightPaneKey` | 测试用 Key。 |

`clampLeftPaneFraction` 是分割条共用的夹取。

分割条用视口 `globalToLocal` 绝对坐标跟指针（无 drag slop、不累加 `delta`）。

### SlidingActions 与 SlidingBackButton

[`SlidingActions`](lib/src/sliding_actions.dart) 由 `MultiColumnScaffold` 写入。视口 AppBar 返回和 [`SlidingBackButton`](lib/src/sliding_back_button.dart) 只调用 `SlidingActions.pop`，不直接依赖宿主路由类。

| API | 作用 |
| --- | --- |
| `SlidingActions.pop` | 壳注入的出栈回调。 |
| `SlidingActions.maybeOf` / `of` | 从栏内读取。 |
| `SlidingBackButton(onPressed:)` | 可选覆盖。缺省：`SlidingActions.pop`，再退到 `controller.pop`。 |

`SlidingBackButton` 只出现在**最右可见栏**，且该栏不是根页（`SlidingPaneScope.showBack`）。

### SlidingPageTitle

每页持有响应式 `title`。页面内：

```dart
SlidingPageTitle.maybeOf(context)?.report('Alice');
```

空标题和未变化的标题会被忽略。`report` 排到**下一帧**写入，以便首帧仍可从 `AppBar.title` 同步。

`SlidingPageTitle.humanize(name)` 把 path 或类型名变成可读标题：去掉 `/`、`:params`、`Page` / `View` 后缀，再在驼峰处插空格。**不是** l10n — 正式文案请传 `resolveTitle`。

### SlidingWindowScope / SlidingPaneScope / inSlidingWindow

| API | 作用 |
| --- | --- |
| `SlidingWindowScope.controller` | 当前 Tab 的栈。 |
| `SlidingWindowScope.maybeOf` / `of` | 读取 scope。 |
| `SlidingPaneScope.index` | 本栏在栈中的下标（`0` 为根）。 |
| `SlidingPaneScope.depth` | 当前栈深度。 |
| `isStackTop` / `showBack` | 是否栈顶；仅 `depth > 1` 且本栏是栈顶时显示返回。 |
| `inSlidingWindow(context)` | 在桌面滑动视口内为 `true`。 |

栏内 Overlay 会被栏边界**裁剪**。菜单 / 遮罩应提升到**根** Overlay：

```dart
PopupMenuButton<String>(
  useRootNavigator: inSlidingWindow(context),
  // ...
)
```

`AdaptiveNavigator.push(..., from: context)` 会从 `from` 读 `SlidingPaneScope`，据此做 `openAfter`。

## 真实项目接入

同一条业务流不要混用 `context.go` / 裸 `Navigator.push` 和 `AdaptiveNavigator`，否则宽屏栈和根路由会分叉。

### 1. 依赖

```yaml
dependencies:
  xue_hua_adaptive_sliding_layout:
    path: ../package/xue_hua_adaptive_sliding_layout
```

### 2. 创建 shell 并喂宽度

```dart
final shell = SlidingShell(tabCount: 2)..init();

// 拥有窗口的 Widget 里：
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

宿主拆除时调用 `shell.dispose()`。

### 3. 每个 Tab 一个 MultiColumnScaffold

用 `IndexedStack` 保活。`onEscapePop` 接到**同一个**负责跳转的 navigator。

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

用 `LayoutBreakpoints.isCompact(width)` 在窄屏 `NavigationBar` 和宽屏 `NavigationRail` 之间切换。`changePage` 只切 Tab。

### 4. 实现 AdaptiveNavigatorFallback

**只用 Navigator**（见 [`example/lib/demo.dart`](example/lib/demo.dart)）：在根 `GlobalKey<NavigatorState>` 上 `push` / `pushReplacement`；命名方法构图方式与 `buildPage` 相同。

**GoRouter**（常见线上宿主）：

| Fallback 方法 | GoRouter / Navigator |
| --- | --- |
| `push` / `pushReplacement` | `Navigator.push` / `pushReplacement` + `MaterialPageRoute` |
| `pushNamed` | `context.pushNamed` |
| `pushReplacementNamed` | `context.goNamed`（换掉当前 location，等同壳层「go」） |
| `pushAndRemoveUntil` | `pushReplacement` |
| `pushNamedAndRemoveUntil` | `pushNamed`（窄屏聊天仍是普通压栈） |
| `pop` / `canPop` | `context.pop` / `context.canPop` |
| `popToRoot` | `Navigator.popUntil(context, (r) => r.isFirst)` |

### 5. 构造 AdaptiveNavigator

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

`handlesRoute: false` 即使滑动栈已开启，也让该页留在宿主导航上（全屏图、登录）。

### 6. 业务跳转全部走这套 navigator

```dart
navigator.pushNamed('/inbox', from: context);
navigator.push(const SettingsPage(), name: '/settings');
navigator.pushReplacementNamed('/replaced');
navigator.pushAndRemoveUntil(const PeerPage(), AdaptiveNavigator.untilRoot);
navigator.pop();
navigator.popToRoot();
```

### 7. 同级替换（聊天）

包不会切 Tab，由宿主做：

```dart
shell.changePage(1); // 会话 Tab
await navigator.pushNamedAndRemoveUntil(
  '/chat',
  AdaptiveNavigator.untilRoot,
  extra: conversationId,
);
```

### 8. 栏内菜单

```dart
useRootNavigator: inSlidingWindow(context)
```

## 注意点

- **`PopScope` 拦不住滑动栈出栈。** 栏内返回走 `LocalHistoryEntry` 加上 `SlidingActions` / `AdaptiveNavigator.pop`。若只要在窄屏拦截，包宿主路由即可。
- **栏内 Overlay 会被裁剪。** 栏里的对话框、菜单、sheet 应使用根 Overlay（`inSlidingWindow`）。
- **根页 key 是固定的。** `ensureRoot` 始终使用 `ValueKey('sliding-root')`。`AdaptiveNavigator.untilRoot` 依赖它。不要换掉根 key。
- **窄屏时滑动栈通常停在根。** 同样的点击走 fallback；可以在宿主栈上 Attachment → Reply → … 一层层 pop，同时 `shell.currentStack.depth` 仍为 `1`。
- **分割条只在松手时回调。** 不要期望 `onLeftPaneFractionChanged` 在每次移动时触发。

## 示例

[`example/`](example/) 是不带 GoRouter 的宿主：窄屏底栏、宽屏 Rail、两个 Tab（`Home`、`Explore`）。

深层 Push Slide 链（每一步都是 `pushNamed(..., from:)`）：

```
Home → Inbox → Thread → Reply → Attachment
  1       2        3        4          5
```

路由：`/inbox`、`/thread/:id`、`/reply/:id`、`/attachment/:id`。

900 宽（`visibleCount == 2`）深度 5 只看见 **Reply + Attachment**。Home / Inbox 仍在栈里。从 Reply 再开另一条 Attachment 会换右栏；`popToRoot` 回到 `[Home]`。

400 宽时同样点击走根 `Navigator`。滑动栈保持 `[Home]`；可以层层 pop：Attachment → Reply → Thread → Inbox → Home。

其他演示动词：`push`（Settings）、`pushAndRemoveUntil`（Peer）、`pushReplacementNamed`（只换栈顶）、`/chat`（`pushNamedAndRemoveUntil` + 切 Tab）、`/photo`（`handlesRoute` 为 false）。

把窗口宽度拖过 600 和 840 即可看到三档。见 [example/README.md](example/README.md)。

## 测试

```bash
cd package/xue_hua_adaptive_sliding_layout && flutter test
cd package/xue_hua_adaptive_sliding_layout/example && flutter test
```

包内 `test/` 覆盖 controller 与 `AdaptiveNavigator` 单测。`example/test` 覆盖三档断点、深度 5 链、左栏 `openAfter`、以及窄屏 fallback 层层 pop。
