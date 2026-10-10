// xue_hua_adaptive_sliding_layout 中文文档内容。
// 依据：包的 README.zh-CN、CHANGELOG、lib/ 与 example/lib。
import '../models/doc_id.dart';
import '../models/doc_page.dart';

DocPage page(DocId id) => switch (id) {
  DocId.quickStart => const DocPage(
    id: DocId.quickStart,
    title: '快速开始',
    description: '写一张路由表交给 MaterialApp.router，再用和 Navigator 同名的动词导航。',
    blocks: [
      DocParagraph(
        '面向 Flutter 的声明式自适应路由。**一张路由表**把 URL 映射成页面栈，再按窗口宽度摆成 1 栏 `Navigator` 或 2 栏滑动视口。调用方式与 `Navigator` 相同：`AdaptiveRouter.of(context).pushNamed(...)`。',
      ),
      DocParagraph('`AdaptiveRouter` 实例由宿主持有，不依赖服务定位器。额外依赖：`signals_flutter`、`material_ui`。'),
      DocHeading('route-table', '声明路由表'),
      DocCode(CodeLanguage.dart, r'''
final router = AdaptiveRouter(
  initialLocation: '/mail',
  routes: [
    AdaptiveShellRoute(
      builder: (context, shell, child) {
        if (!shell.isCompact) return Scaffold(body: child);
        return AdaptiveShellChrome(
          bottomNavigationBar: (context) => NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) => shell.goBranch(i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.mail), label: 'Mail'),
              NavigationDestination(icon: Icon(Icons.people), label: 'Contacts'),
            ],
          ),
          child: child,
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

MaterialApp.router(routerConfig: router);'''),
      DocHeading('navigate', '在页面里导航'),
      DocCode(CodeLanguage.dart, r'''
final router = AdaptiveRouter.of(context);
router.pushNamed('/mail/inbox');
router.pushNamed(
  router.namedLocation('thread', pathParameters: {'folder': 'inbox', 'threadId': '42'}),
  arguments: thread,
);
router.pop();'''),
      DocCallout(CalloutKind.tip, '示例应用就是接入模板：完整路由表可直接从 `example/lib/router/router_pages.dart` 复制。'),
      DocHeading('next', '下一步'),
      DocList(['在 [URL → 栈 → 栏位](doc:url-stack-panes) 中了解 location 如何变成页面栈。', '所有路由参数见 [路由表](doc:route-table)。']),
    ],
  ),
  DocId.installation => const DocPage(
    id: DocId.installation,
    title: '安装',
    description: 'SDK 要求、依赖以及如何添加本包。',
    blocks: [
      DocHeading('requirements', '环境要求'),
      DocTable(
        ['项目', '约束'],
        [
          ['Dart SDK', '`^3.13.0`'],
          ['Flutter', '`>=3.47.0`'],
          ['依赖', '`signals_flutter: ^7.1.0`, `material_ui: ^1.6.0`'],
        ],
      ),
      DocHeading('add', '添加依赖'),
      DocCode(CodeLanguage.shell, 'flutter pub add xue_hua_adaptive_sliding_layout'),
      DocCode(CodeLanguage.yaml, '''
dependencies:
  xue_hua_adaptive_sliding_layout: ^3.4.3''', fileName: 'pubspec.yaml'),
      DocCode(
        CodeLanguage.dart,
        "import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';",
      ),
      DocHeading('run-example', '运行示例'),
      DocCode(CodeLanguage.shell, '''
cd example && flutter run -d chrome
cd example && flutter test'''),
      DocHeading('tests', '运行包的测试'),
      DocCode(CodeLanguage.shell, '''
flutter analyze && flutter test
cd example && flutter analyze && flutter test'''),
    ],
  ),
  DocId.urlStackPanes => const DocPage(
    id: DocId.urlStackPanes,
    title: 'URL → 栈 → 栏位',
    description: 'location 如何匹配成页面栈，并摆成一个 Navigator 或两栏滑动视口。',
    blocks: [
      DocCode(CodeLanguage.plain, '''
URL /mail/inbox/42/reply
  → RouteInformationParser
  → MatchList [mail, inbox, 42, reply]
  → RouterDelegate → AdaptiveShellRoute.builder
      窗口宽度 < 840   → 1 栏：Navigator pages
      窗口宽度 >= 840  → 2 栏：SlidingPaneViewport（最后 2 栏）
  → fullscreen / 壳外路由 → 根 Navigator'''),
      DocHeading('stack', '匹配列表就是页面栈'),
      DocParagraph('`/mail/inbox/42/reply` 沿路由树匹配出一串 match，这一串**就是**页面栈。'),
      DocHeading('panes', '一栏还是两栏'),
      DocParagraph(
        '低于 `expandedMinWidth`（默认 840）时走经典 `Navigator`；达到该宽度时，最后两层并排显示在 `SlidingPaneViewport` 中，更深的页面会把旧栏推向左侧。',
      ),
      DocParagraph('`fullscreen: true` 与 `fullscreenDialog: true` 的匹配叠在**根** Navigator 上（登录、看图、写信对话框等）。'),
      DocHeading('web', '返回、深链与 Web'),
      DocParagraph(
        '浏览器后退、深链、刷新都只是换了一个 location，走的是同一条路径。Web 使用默认的 **hash** 策略（`/#/mail/inbox/42`），部署到 GitHub Pages 不需要 404 回退。',
      ),
    ],
  ),
  DocId.routeTable => const DocPage(
    id: DocId.routeTable,
    title: '路由表',
    description: 'AdaptiveRouter、AdaptiveRoute、AdaptiveShellRoute、AdaptiveBranch，以及传给 builder 的状态对象。',
    blocks: [
      DocHeading('types', '类型'),
      DocTable(
        ['类型', '职责'],
        [
          [
            '`AdaptiveRouter`',
            '`RouterConfig<AdaptiveRouteMatchList>`。导航动词 + `namedLocation` / `refresh`。只读 signal：`location`、`matches`、`currentBranch`。`of` / `maybeOf`。',
          ],
          [
            '`AdaptiveRoute`',
            '一个页面。`path`、可选 `name`、`builder`、`title`、`fullscreen`、`fullscreenDialog`、`hidesBottomBarWhenPushed`、`opaque`、`barrierColor`、`barrierDismissible`、`transitionsBuilder`、`redirect`、`onExit`、子 `routes`。',
          ],
          [
            '`AdaptiveShellRoute`',
            'Tab + 自适应外壳。整棵树只能有一个，且必须在顶层。`builder(context, shell, child)`、`branches`、`breakpoints`、分割条 / 面包屑，以及各种 [UI 参数](doc:customizing-ui)。',
          ],
          [
            '`AdaptiveShellChrome`',
            'compact 底栏。`bottomNavigationBar` 是一个 `WidgetBuilder`。底栏位于分支页面内部，所以 `useRootNavigator: false` 的 sheet 能盖住它。不要再同时设置 `Scaffold.bottomNavigationBar`。',
          ],
          ['`AdaptiveBranch`', '一个 Tab。`routes`，可选 `initialLocation` / `placeholder`。'],
          [
            '`AdaptiveRouteState`',
            'builder 的参数，也可通过 `AdaptiveRouteState.of(context)` 获取：`uri`、`matchedLocation`、`fullPath`、`name`、`pathParameters`、`queryParameters`、`arguments`、`error`、`pageKey`。',
          ],
          [
            '`AdaptiveShellState`',
            '外壳 builder 的参数：`currentIndex`、宽度 / 断点（`isCompact`、`isMedium`、`isExpanded`）、`leftPaneFraction`、`goBranch`。',
          ],
          ['`LayoutBreakpoints`', '`const` 类，默认 `compactMaxWidth: 600`、`expandedMinWidth: 840`。'],
        ],
      ),
      DocHeading('paths', '路径规则'),
      DocList(['子路径相对于父路由。', '`:param` 表示一个路径段。', '按声明顺序，先匹配者优先。']),
      DocCallout(CalloutKind.info, '页面由 `builder` + `transitionsBuilder` 提供，因为宽屏栏位需要的是 `Widget`，而不是 `Page`。'),
      DocHeading('redirect', '重定向与错误页'),
      DocParagraph(
        '顶层 `redirect` 与路由级 `redirect` 都可以返回新的 location（`FutureOr<String?>`）。跳转次数超过 `redirectLimit`（5）视为循环，进入 `errorBuilder`。示例中这样保护账号页：',
      ),
      DocCode(CodeLanguage.dart, r'''
AdaptiveRouter(
  initialLocation: RouterNames.splash,
  redirect: (context, state) {
    final path = state.uri.path;
    if (path.startsWith(RouterNames.account) &&
        !AppSettingServices.instance.signedIn.value) {
      return '${RouterNames.login}?from=${Uri.encodeComponent(state.uri.toString())}';
    }
    return null;
  },
  errorBuilder: (context, state) => NotFoundPage(uri: state.uri),
  routes: [
    AdaptiveRoute(path: '/', redirect: (_, _) => RouterNames.splash),
    // ...
  ],
)''', fileName: 'example/lib/router/router_pages.dart'),
      DocHeading('on-exit', '用 onExit 拦截离开'),
      DocCode(CodeLanguage.dart, r'''
AdaptiveRoute(
  path: 'edit',
  name: RouterNames.contactEdit,
  onExit: (context, state) async {
    if (!ContactServices.instance.remarkDirty.value) return true;
    final leave = await showDialog<bool>(
      context: context,
      useRootNavigator: AdaptivePaneScope.maybeOf(context) != null,
      builder: (dialogContext) => AlertDialog(/* ... */),
    );
    return leave == true;
  },
  builder: (context, state) => const ContactEditPage(),
)'''),
    ],
  ),
  DocId.navigationVerbs => const DocPage(
    id: DocId.navigationVerbs,
    title: '导航动词',
    description: '与 Navigator 同名的导航动词、它们在单栏 / 双栏下的行为、Tab 切换与退出确认。',
    blocks: [
      DocParagraph(
        '名称和签名与 `NavigatorState` 一致，`routeName` 就是 location。不提供非 Named 的 `push(Route)`：所有页面都必须在路由表中，URL 才能表达它。',
      ),
      DocHeading('verbs', '动词一览'),
      DocTable(
        ['调用', '行为'],
        [
          [
            '`pushNamed`',
            '压入分支 `Navigator`；`fullscreen` / 壳外路由则叠到根上。同分支且当前栈是目标前缀时补齐尾部（`/mail` → `/mail/inbox/42` 可一次滑入两栏）。同分支但不是前缀时把叶子压到栈顶（`/mail/inbox/41` → `/mail/inbox/42` 得到 `[mail, inbox, 41, 42]`）。其他分支：切换 Tab 并按 URL 重建该分支的栈。',
          ],
          ['`pushReplacementNamed`', '只替换栈顶。同级替换，右栏原地更新内容。'],
          [
            '`pushNamedAndRemoveUntil`',
            '先弹出直到 predicate 为 true，再 `pushNamed`。`(_) => false` 会按 URL 重建（深链、登录回跳、Tab 回根）。',
          ],
          ['`popAndPushNamed`', '先 `pop` 再 `pushNamed`。'],
          ['`pop`', '立即弹出，**不询问** `onExit`。栈顶页上有 dialog / sheet / menu 时只关闭那一层。'],
          [
            '`maybePop`',
            '先询问栈顶页内的 `PopScope`，再询问路由的 `onExit`。AppBar 返回、系统返回、浏览器后退、Escape 都走它。它不带 context，只处理**栈顶那一栏**以及盖住整体的根 / 外壳弹层。',
          ],
          [
            '`popFrom(context)`',
            '只作用于 `context` 所在的那一层：在 dialog / sheet 里就关闭它；在某个页面里就关闭盖住该页的弹层，若没有弹层且该页是栈顶则弹出该页。**不询问** `onExit`。',
          ],
          ['`maybePopFrom(context)`', '`popFrom` 的询问版：弹层走自己的 `PopScope`，页面依次走 `PopScope` → `onExit`。'],
          ['`popUntil`', '弹出直到 predicate 为 true，不会越过分支根。'],
          ['`canPop`', '存在覆盖层，或当前分支深度 > 1。'],
        ],
      ),
      DocParagraph('`pushNamed` 返回的 `Future` 由 `pop(result)` 完成。'),
      DocHeading('helpers', '辅助方法'),
      DocList([
        '`namedLocation(name, pathParameters:, queryParameters:)` 把路由名和参数拼成 location，供 `*Named` 动词使用。',
        '`refresh()` 在登录状态变化后重新执行 redirect。',
      ]),
      DocHeading('tabs', '切换 Tab'),
      DocParagraph(
        '切换 Tab 不是 Navigator 动词，请用 `AdaptiveShellState.goBranch(index, {initialLocation})`。内部等价于对该分支上次所在位置（或 `initialLocation`）执行 `pushNamedAndRemoveUntil`。再次点击**当前** Tab 并传 `initialLocation: true`，即可回到分支根：',
      ),
      DocCode(CodeLanguage.dart, '''
if (index == shell.currentIndex) {
  shell.goBranch(index, initialLocation: true);
} else {
  shell.goBranch(index);
}'''),
      DocHeading('confirm-exit', '退出应用前确认'),
      DocParagraph(
        '在外壳 `builder`（或某个 Tab 根页）中放一个 `PopScope(canPop: false)`。系统返回会触发 `onPopInvokedWithResult(false)`，你可以先弹出确认框，再调用 `SystemNavigator.pop()`。',
      ),
      DocCallout(
        CalloutKind.warning,
        '对话框请用 `showDialog(useRootNavigator: false)`，与 `PopScope` 处在同一个 Navigator；如果挂到根 Navigator，关闭后再按返回会被 Android 直接退出。兼容 Android 预测性返回。在根部按 Escape 不会触发此逻辑。',
      ),
    ],
  ),
  DocId.readingState => const DocPage(
    id: DocId.readingState,
    title: '读取状态',
    description: '读取 location、路由参数、栏位与外壳作用域，并设置面包屑标题。',
    blocks: [
      DocCode(CodeLanguage.dart, '''
AdaptiveRouter.of(context).location.value;          // '/mail/inbox/42'
AdaptiveRouteState.of(context).pathParameters;      // {'folder': 'inbox', ...}
AdaptivePaneScope.maybeOf(context)?.title.value = subject; // breadcrumbs
AdaptiveShellScope.maybeOf(context)?.isExpanded;'''),
      DocHeading('pane-scope', 'AdaptivePaneScope'),
      DocParagraph(
        '`AdaptivePaneScope.maybeOf` 仅在双栏的栏位内非 null，用来替代 2.x 的 `inSlidingWindow` / `SlidingPageTitle`。异步标题：数据到达后写入 `title.value` 即可，包不再遍历 Element 树去读取 `AppBar.title`。',
      ),
      DocHeading('route-titles', '路由标题与国际化'),
      DocParagraph(
        '`AdaptiveRoute.title(state)` 在匹配时只求值一次，没有 `BuildContext`；`state.fullPath` 是完整的路径模式，`state.uri` 带有查询参数。',
      ),
      DocList([
        '要国际化，请用不依赖 context 的查找：gen-l10n 的 `lookupAppLocalizations(locale)`（locale 取 `WidgetsBinding.instance.platformDispatcher.locale` 或你自己的 locale signal），或 `intl` 的 `Intl.defaultLocale`。',
        '如果需要 context，或标题要随语言实时切换，请改为在页面中设置 `AdaptivePaneScope.maybeOf(context)?.title.value`；静态的 `title` 不会在语言变化时重新求值。',
      ]),
      DocHeading('signals', '在 UI 中订阅'),
      DocParagraph(
        '在 UI 中用 `SignalBuilder` 订阅（见 `signals_flutter`）。想在**自己的**外壳里绘制标题而不是用内置条带，可读取 `AdaptiveRouter.of(context).matches.value.branchMatches`（每个 match 都有 `title` signal 和 `name`）。',
      ),
    ],
  ),
  DocId.customizingUi => const DocPage(
    id: DocId.customizingUi,
    title: '自定义 UI',
    description: '视口、分割条、面包屑与覆盖层路由的 builder 和数值参数。',
    blocks: [
      DocParagraph(
        '用 **builder** 替换结构，用**数值参数**微调。主题颜色仍取自 `Theme.of(context)`。单栏的页面转场使用 Flutter 的 `ThemeData.pageTransitionsTheme`。',
      ),
      DocHeading('viewport', '视口（SlidingPaneViewport / AdaptiveShellRoute）'),
      DocTable(
        ['参数', '默认值', '作用'],
        [
          ['`slideDuration`', '280ms', '栏位滑动时长'],
          ['`slideCurve`', '`Curves.easeOutCubic`', '栏位滑动曲线'],
          ['`paneBuilder`', '双栏卡片 / 单栏平铺', '包裹每一栏。`index == panes.length` 表示右侧空位'],
          [
            '`resizeHandleBuilder`',
            '圆角动画条',
            '`Widget Function(BuildContext context, bool isHovered)`；悬停或拖动时以 `colorScheme.primary` 高亮',
          ],
          ['`resizeHandleWidth`', '4（外壳路由）', '分割条的点击区域宽度；`SlidingPaneViewport` 上为必填'],
          ['`resizeHandleMargin`', '—', '独立于点击区域设置分割条的内边距'],
          ['`placeholder`', '描边图标', '外壳级的右侧空栏；若设置了 `AdaptiveBranch.placeholder` 则以它为准'],
        ],
      ),
      DocParagraph('默认分栏比例：左栏 0.4，左 / 右栏最小比例均为 0.35。'),
      DocHeading('example-shell', '示例：Demo 中的外壳路由'),
      DocCode(CodeLanguage.dart, '''
AdaptiveShellRoute(
  showBreadcrumbs: true,
  resizable: true,
  initialLeftPaneFraction: 0.4,
  placeholder: (context) => const EmptyPage(),
  slideDuration: const Duration(milliseconds: 280),
  resizeHandleBuilder: (context, isHovered) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      height: double.infinity,
      margin: .symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isHovered ? colorScheme.primary : colorScheme.surfaceDim,
      ),
    );
  },
  breadcrumbsBuilder: (context, panes, onSelect) {
    return AdaptiveBreadcrumbs(
      panes: panes,
      onSelect: onSelect,
      height: 32,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  },
  paneBuilder: (context, index, child) {
    return Card(
      margin: .symmetric(horizontal: 8, vertical: 8),
      child: KeyedSubtree(key: const Key('pane-flat'), child: child),
    );
  },
  builder: (context, shell, child) => AppShell(shell: shell, child: child),
  branches: [/* ... */],
)''', fileName: 'example/lib/router/router_pages.dart'),
      DocHeading('breadcrumbs', '面包屑'),
      DocTable(
        ['参数', '默认值', '作用'],
        [
          ['`height`', '32', '条带高度'],
          ['`padding`', '水平 12', '条带内边距'],
          ['`backgroundColor`', '`surfaceContainerLow`', '条带颜色'],
          ['`itemBuilder`', 'InkWell + Text', '单个面包屑'],
          ['`separatorBuilder`', '箭头', '面包屑之间的分隔'],
          ['`AdaptiveShellRoute.breadcrumbsBuilder`', '`AdaptiveBreadcrumbs`', '替换整条面包屑（仍受 `showBreadcrumbs` 控制）'],
          ['`escapePops`', 'true', '按 Escape 调用 `maybePop`'],
        ],
      ),
      DocHeading('bottom-bar', '底栏行为'),
      DocParagraph(
        'medium / expanded 下，子页面保留宿主外壳。compact 下，分支根以下的页面默认隐藏底栏（`hidesBottomBarWhenPushed`；设为 `false` 可保留）。外壳使用 `AdaptiveShellChrome` 时，Tab 根页上的底部弹层（`useRootNavigator: false`）会盖住底栏；而 `Scaffold.bottomNavigationBar` 位于分支 Navigator 之外，同样的弹层不会盖住它。',
      ),
      DocHeading('overlay-routes', '覆盖层路由（AdaptiveRoute）'),
      DocTable(
        ['参数', '默认值', '作用'],
        [
          ['`hidesBottomBarWhenPushed`', 'true', '仅 compact：压入的页面盖住宿主底栏；桌面双栏不受影响'],
          ['`fullscreen`', 'false', '任意宽度都走根 Navigator，普通转场'],
          ['`fullscreenDialog`', 'false', '任意宽度都走根 Navigator，以 Material 全屏对话框呈现'],
          ['`opaque`', 'true', '配合 `transitionsBuilder` 可做透明看图页'],
          ['`barrierColor`', 'null', '配合 `transitionsBuilder` 使用'],
          ['`barrierDismissible`', 'false', '点击遮罩即返回'],
        ],
      ),
      DocCode(CodeLanguage.dart, '''
AdaptiveRoute(
  path: 'preview',
  name: RouterNames.preview,
  title: (_) => '图片预览',
  fullscreen: true,
  opaque: false,
  barrierColor: Colors.black,
  barrierDismissible: true,
  transitionDuration: const Duration(milliseconds: 200),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(opacity: animation, child: child);
  },
  builder: (context, state) => const ImagePreviewPage(),
)'''),
    ],
  ),
  DocId.layoutWithoutRouter => const DocPage(
    id: DocId.layoutWithoutRouter,
    title: '不用路由只要布局',
    description: '直接使用 SlidingPaneViewport、SlidingPane 与 AdaptiveBreadcrumbs，以及宽度断点说明。',
    blocks: [
      DocParagraph('如果只想要滑动分栏，`SlidingPaneViewport`、`SlidingPane` 与 `AdaptiveBreadcrumbs` 都是公开 API，可以单独使用。'),
      DocHeading('widgets', '基础组件'),
      DocTable(
        ['组件', '主要参数'],
        [
          [
            '`SlidingPaneViewport`',
            '必填：`panes`（`List<SlidingPane>`）、`visibleCount`、`resizeHandleWidth`。可选：`onPop`、`placeholder`、`leftPaneFraction`、`minLeftPaneFraction`、`minRightPaneFraction`、`onLeftPaneFractionChanged`、`slideDuration`、`slideCurve`、`paneBuilder`、`resizeHandleMargin`、`resizeHandleBuilder`。',
          ],
          ['`SlidingPane`', '`key`（`LocalKey`，深度变化时必须保持稳定，栏内 State 才不会重建）、`title`（`Signal<String>`）、`child`。'],
          [
            '`AdaptiveBreadcrumbs`',
            '必填：`panes`、`onSelect`（传入被点击的栏）。可选：`height`、`padding`、`backgroundColor`、`itemBuilder`、`separatorBuilder`。',
          ],
        ],
      ),
      DocHeading('breakpoints', '断点'),
      DocParagraph('断点依据的是窗口宽度，而不是设备类型：'),
      DocTable(
        ['宽度', '档位', '可见栏数'],
        [
          ['`< compactMaxWidth` (600)', 'compact', '1 — `Navigator`（全屏栈）'],
          ['600–839', 'medium', '1 — 同一个 `Navigator`；宿主可用 `shell.isMedium` 调整外壳'],
          ['`≥ expandedMinWidth` (840)', 'expanded', '2 — 最后两栏 + 可选分割条'],
        ],
      ),
      DocCallout(
        CalloutKind.info,
        '视口只支持 1 栏或 2 栏。要支持三栏及以上，需要修改 `visibleColumnCount`，并让 `SlidingPaneViewport` 能排布 N 栏。',
      ),
    ],
  ),
  DocId.exampleScenarios => const DocPage(
    id: DocId.exampleScenarios,
    title: '示例场景',
    description: '示例应用演示了哪些功能，以及对应的代码位置。',
    blocks: [
      DocParagraph('`example/` 就是接入模板。在 Web Demo 中，顶部栏可固定为手机 / 折叠屏 / 平板 / 桌面宽度，无需拖动窗口就能看到每个断点的效果。'),
      DocHeading('areas', '功能模块'),
      DocTable(
        ['模块', '演示内容', '文件'],
        [
          ['认证', '全屏的启动 / 登录 / 注册路由；访问账号页时 `redirect` 到 `/login?from=`', '`pages/auth/`'],
          ['首页', '商品列表 → `/home/:id` 详情（`title` 根据 id 解析），以及使用 `transitionsBuilder` 的半透明全屏图片预览', '`pages/home/`'],
          ['购物车', '拥有独立栈的单独分支', '`pages/shopping_cart/`'],
          [
            '联系人',
            '列表 → `/contacts/:id` → `edit`；`onExit` 确认框，并根据 `AdaptivePaneScope` 决定 `useRootNavigator`',
            '`pages/contacts/`',
          ],
          ['我的', '嵌套的 `theme` / `account` 页面，`about` 以 `fullscreenDialog` 打开', '`pages/mine/`'],
          [
            '外壳',
            'compact 下 `AdaptiveShellChrome` 内的 `NavigationBar` 与宽屏 `NavigationRail`；再次点击 Tab 通过 `goBranch(i, initialLocation: true)` 回根；`PopScope` 退出确认',
            '`shell/app_shell.dart`',
          ],
          ['路由', '完整路由表、面包屑、自定义分割条与卡片式栏位', '`router/router_pages.dart`'],
        ],
      ),
      DocHeading('run', '运行'),
      DocCode(CodeLanguage.shell, '''
cd example && flutter run -d chrome
cd example && flutter test'''),
    ],
  ),
  DocId.migrating2x => const DocPage(
    id: DocId.migrating2x,
    title: '从 2.x 迁移',
    description: '把 2.x 的 SlidingShell 系列 API 对应到 3.x 的路由表。',
    blocks: [
      DocTable(
        ['2.x', '3.x'],
        [
          [
            '`SlidingShell` + 每个 Tab 一个 `MultiColumnScaffold` + `AdaptiveNavigator` + 9 个回调方法',
            '一个 `AdaptiveRouter` + `MaterialApp.router`',
          ],
          ['`handlesRoute` / `buildPage` / `resolveTitle`', '路由表中的 `AdaptiveRoute`'],
          ['`from:` / `openAfter` / `openSecondary`', 'URL 即栈（`pushNamed` 前缀补齐 / 追加）'],
          ['`extra`', '`arguments`'],
          ['`inSlidingWindow(context)`', '`AdaptivePaneScope.maybeOf(context) != null`'],
          ['`SlidingPageTitle.report`', '`AdaptivePaneScope.maybeOf(context)?.title.value = …`'],
          ['`SlidingActions.pop`', '`AdaptiveRouter.of(context).maybePop()`'],
        ],
      ),
      DocCallout(CalloutKind.warning, '没有兼容层，所有破坏性变更请查看 CHANGELOG。'),
    ],
  ),
  DocId.migratingGoRouter => const DocPage(
    id: DocId.migratingGoRouter,
    title: '从 go_router 迁移',
    description: '写给 go_router 用户的概念与调用对照表。',
    blocks: [
      DocTable(
        ['go_router', '本包'],
        [
          ['`GoRoute`', '`AdaptiveRoute`'],
          ['`StatefulShellRoute.indexedStack`', '`AdaptiveShellRoute` + `AdaptiveBranch`'],
          ['`context.go(loc)`', '`router.pushNamedAndRemoveUntil(loc, (_) => false)`'],
          ['`context.push(loc)`', '`router.pushNamed(loc)`'],
          ['`extra`', '`arguments`'],
          ['`GoRouterState`', '`AdaptiveRouteState`'],
          ['`pageBuilder`', '`builder` + 可选的 `transitionsBuilder`'],
          ['`context.go` / `context.pop` 扩展方法', '只用 `AdaptiveRouter.of(context)`'],
        ],
      ),
    ],
  ),
  DocId.caveats => const DocPage(
    id: DocId.caveats,
    title: '注意点',
    description: '关于断点、弹层、返回语义与 Web 的已知限制。',
    blocks: [
      DocHeading('breakpoint-rebuild', '跨越断点会重建 State'),
      DocParagraph('跨越 840 断点会**重建**页面 `State`（Navigator 树 ↔ 视口树）。需要持久的状态请放进 URL、signal 或宿主的存储中。'),
      DocHeading('overlays', '栏内弹层会被裁剪'),
      DocParagraph(
        '栏内的对话框、菜单、底部弹层应走根 Overlay：`useRootNavigator: AdaptivePaneScope.maybeOf(context) != null`。compact 下 Tab 根页的 sheet 仍挂在最近的 Navigator 上，只有外壳使用 `AdaptiveShellChrome` 时才会盖住底栏。',
      ),
      DocHeading('context-free-pop', '不带 context 的 pop'),
      DocParagraph(
        '不带 context 的 `pop` / `maybePop`（包括 Escape 和系统返回）只处理栈顶那一栏，以及盖住整体的根 / 外壳弹层。**另一栏**里的栏内 sheet / dialog 不会被它们关闭：请用 `maybePopFrom(context)`，或在弹层内直接调用 `Navigator.pop(context)`。多个弹层叠加时，从最外层开始关闭（根 → 外壳 → 栏内）。',
      ),
      DocHeading('on-exit', 'onExit 何时执行'),
      DocParagraph(
        '`onExit` 在 `maybePop`、系统返回和浏览器后退时被询问，且排在栈顶页的 `PopScope` 之后。处于栈底时，系统返回会在退出应用前询问该路由的 `onExit`。`pop` / `pushReplacementNamed` / `pushNamedAndRemoveUntil` 与 `Navigator` 一样立即执行。',
      ),
      DocHeading('web', 'Web'),
      DocParagraph('Web 保持 hash URL。平台提供的初始路由不是 `/` 时，它优先于 `initialLocation`。'),
      DocHeading('limits', '范围限制'),
      DocCallout(
        CalloutKind.danger,
        '整棵树只允许一个顶层 `AdaptiveShellRoute`。不支持嵌套外壳、`restorable*`，也不提供 `context.pushNamed` 扩展方法。',
      ),
    ],
  ),
  DocId.packageSkills => const DocPage(
    id: DocId.packageSkills,
    title: 'Package Skills',
    description: '安装本包附带的 agent skills，让编码助手按真实 API 写代码。',
    blocks: [
      DocParagraph(
        '本包在 `skills/` 目录下提供 [agent skills](https://dart.dev/tools/pub/package-skills)。添加依赖后安装它们，编码助手就会按真实 API 写代码：',
      ),
      DocCode(CodeLanguage.shell, 'dart run skills@ get -p xue_hua_adaptive_sliding_layout --all'),
      DocHeading('skills', 'Skill 列表'),
      DocTable(
        ['Skill', '适用场景'],
        [
          ['`xue-hua-adaptive-sliding-layout-setup`', '`AdaptiveRouter` + `MaterialApp.router`'],
          ['`xue-hua-adaptive-sliding-layout-routing`', '路由表、`:param`、`redirect`、`onExit`'],
          ['`xue-hua-adaptive-sliding-layout-navigation`', '`pushNamed` / `pop` / `goBranch`'],
          ['`xue-hua-adaptive-sliding-layout-layout`', '栏位、断点、面包屑'],
        ],
      ),
    ],
  ),
};
