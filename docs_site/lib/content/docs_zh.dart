// xue_hua_adaptive_sliding_layout 中文文档内容。
// 依据：包的 README.zh-CN、CHANGELOG、lib/ 与 example/lib。
//
// 页面按渐进式教程组织：每一页都从上一页完整的 `lib/main.dart`
//（见 tutorial_code.dart）出发，只增加一个新概念。
import '../models/doc_id.dart';
import '../models/doc_page.dart';
import 'tutorial_code.dart';

DocPage page(DocId id) => switch (id) {
  DocId.introduction => const DocPage(
    id: DocId.introduction,
    title: '介绍',
    description: 'xue_hua_adaptive_sliding_layout 解决什么问题，以及一张路由表如何变成一栏或两栏。',
    blocks: [
      DocParagraph('手机应用习惯整屏推入新页面；平板和桌面应用则更常见**列表与详情并排**显示。两种形态各写一套导航，时间一长就会对不上。'),
      DocParagraph('`xue_hua_adaptive_sliding_layout` 只要**一张路由表**。URL 被解析成一个页面栈，再由窗口宽度决定这个栈怎么摆：'),
      DocLayoutDiagram(
        compactLabel: '窄窗口（< 840）：一栏',
        expandedLabel: '宽窗口（≥ 840）：两栏滑动',
        listLabel: '商品',
        detailLabel: '咖啡杯',
        caption: '同一个 URL `/products/1`，同一个栈 `[商品, 咖啡杯]`。窄窗口用普通 `Navigator` 显示栈顶页；宽窗口把最后两页并排，并带面包屑和可拖动的分隔条。',
      ),
      DocHeading('how', '一句话说清原理'),
      DocCode(CodeLanguage.plain, '''
URL /products/1/reviews
  → 匹配路由表      → 栈 [products, 1, reviews]
  → 窗口宽度 < 840  → 一栏：Navigator 显示 "reviews"
  → 窗口宽度 ≥ 840  → 两栏："1" | "reviews"（"products" 滑出到左侧）'''),
      DocParagraph(
        '导航用的是你在 `Navigator` 上早就熟悉的动词——`pushNamed`、`pop`、`maybePop`……——只是调用在 `AdaptiveRouter.of(context)` 上。返回按钮、系统返回、浏览器后退、深链接和刷新都经过同一个 URL，所以页面栈始终一致。',
      ),
      DocHeading('tutorial', '你将做出什么'),
      DocParagraph('教程会一步步做出一个小型商店应用。每一步都给出可以直接粘贴的完整 `lib/main.dart`：'),
      DocList([
        '[第一个应用](doc:first-app)：一条路由，接入 `MaterialApp.router`。',
        '[嵌套路由](doc:nested-routes)：商品列表和 `/products/:id` 详情页。',
        '[页面间导航](doc:navigation)：推入、返回、回传结果、替换、重置。',
        '[添加 Tab](doc:tabs)：「商品」和「账户」两个 Tab，各自维护自己的栈。',
        '[双栏与断点](doc:two-columns)：840 像素处发生了什么、占位页、分隔条。',
        '[标题与面包屑](doc:titles-and-breadcrumbs)，然后是[重定向、登录与 onExit](doc:redirects-and-on-exit)。',
        '最后是[自定义 UI](doc:customizing-ui)、[读取状态](doc:reading-state)以及[不用路由只用布局](doc:layout-without-router)。',
      ], ordered: true),
      DocCallout(
        CalloutKind.tip,
        '想先看看最终效果？打开[在线 Demo](https://matkurban.github.io/xue_hua_adaptive_sliding_layout/example/)，用顶部的宽度预设（手机 / 平板 / 桌面）切换，就能看到同一组页面在一栏和两栏之间变化。',
      ),
      DocParagraph('**下一步：**[安装](doc:installation)。'),
    ],
  ),
  DocId.installation => const DocPage(
    id: DocId.installation,
    title: '安装',
    description: 'SDK 要求，以及教程用到的三个依赖。',
    blocks: [
      DocCallout(CalloutKind.info, '把包加入一个 Flutter 应用，并确认导入能通过编译。', title: '目标'),
      DocHeading('requirements', '环境要求'),
      DocTable(
        ['项目', '约束'],
        [
          ['Flutter', '`>=3.47.0`'],
          ['Dart SDK', '`^3.13.0`'],
          ['包自身的依赖', '`signals_flutter: ^7.1.0`、`material_ui: ^1.6.0`'],
        ],
      ),
      DocHeading('add', '添加依赖'),
      DocParagraph(
        '新建一个应用（或使用已有应用）并添加本包。教程代码还会直接导入 `material_ui`（Material 组件，和包的示例一致）和 `signals_flutter`（后面用来存一点应用状态），所以把它们也直接加上：',
      ),
      DocCode(CodeLanguage.shell, '''
flutter create shop
cd shop
flutter pub add xue_hua_adaptive_sliding_layout material_ui signals_flutter'''),
      DocParagraph('此时 `pubspec.yaml` 中会有：'),
      DocCode(CodeLanguage.yaml, '''
dependencies:
  flutter:
    sdk: flutter
  xue_hua_adaptive_sliding_layout: ^3.4.3
  material_ui: ^1.6.0
  signals_flutter: ^7.1.0''', fileName: 'pubspec.yaml'),
      DocHeading('imports', '导入'),
      DocParagraph('教程里的每个文件都以这两行导入开头：'),
      DocCode(CodeLanguage.dart, '''
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';'''),
      DocCallout(CalloutKind.tip, '在用编码助手？本包附带 agent skills，能让助手按真实 API 写代码，见 [AI：Skills](doc:skills)。'),
      DocParagraph('**下一步：**[第一个应用](doc:first-app)。'),
    ],
  ),
  DocId.firstApp => const DocPage(
    id: DocId.firstApp,
    title: '第一个应用',
    description: '最小可运行的应用：AdaptiveRouter 里只有一条路由，交给 MaterialApp.router。',
    blocks: [
      DocCallout(CalloutKind.info, '运行一个应用，它唯一的页面来自 `AdaptiveRouter` 路由表。', title: '目标'),
      DocHeading('code', '完整代码'),
      DocParagraph('把 `lib/main.dart` 替换为：'),
      DocCode(CodeLanguage.dart, firstAppMain, fileName: 'lib/main.dart'),
      DocHeading('explained', '每一部分在做什么'),
      DocList([
        '**`AdaptiveRouter`** 就是路由表。创建一次，放在顶层变量（或你的应用自己持有的任何对象）里即可，不需要服务定位器。`initialLocation` 是平台没有给出 URL 时的起始位置。',
        '**`AdaptiveRoute`** 表示一个页面：一个 `path`，加一个返回普通 Widget 的 `builder(context, state)`。',
        '**`MaterialApp.router(routerConfig: router)`** 把路由接入 Flutter。`AdaptiveRouter` 本身就是 `RouterConfig`，不需要别的配置。',
        '**`ProductsPage`** 只是一个普通的 `Scaffold`。页面不需要继承或了解包里的任何东西。',
      ], ordered: true),
      DocHeading('run', '运行'),
      DocCode(CodeLanguage.shell, 'flutter run -d chrome'),
      DocParagraph(
        '你会看到一个标题为 **Products** 的页面，中间写着 “Hello from /products”。在 Web 上地址栏显示 `/#/products`：路由使用 hash URL，所以应用可以部署在任何静态服务器上（包括 GitHub Pages），不需要配置重写规则。',
      ),
      DocCallout(CalloutKind.tip, '只有一个页面还谈不上自适应。真正有意思的地方从出现**页面栈**开始——这就是下一步。'),
      DocParagraph('**下一步：**[嵌套路由与参数](doc:nested-routes)。'),
    ],
  ),
  DocId.nestedRoutes => const DocPage(
    id: DocId.nestedRoutes,
    title: '嵌套路由与参数',
    description: '在 /products/:id 添加商品详情页，读取路径参数和查询参数。',
    blocks: [
      DocCallout(CalloutKind.info, '点击列表中的商品打开 `/products/:id`，并理解为什么列表始终垫在下面。', title: '目标'),
      DocHeading('rules', '三条路径规则'),
      DocList([
        '**子路径相对于父路径**：`/products` 下的子路由 `:id` 匹配 `/products/1`。',
        '**`:param` 只匹配一个路径段**，值放在 `state.pathParameters` 里。',
        '**先声明的先匹配。**',
      ]),
      DocParagraph(
        '匹配 `/products/2` 时会沿着路由树把途经的每条路由都收集起来：`[products, 2]`。**这个列表就是页面栈。**所以直接深链接到详情页时，下面依然垫着列表，返回就回到列表。',
      ),
      DocHeading('code', '完整代码'),
      DocParagraph('与上一步相比：多了一个小小的 `Product` 模型、一条子路由 `:id`、一个调用 `pushNamed` 的列表，以及详情页。'),
      DocCode(CodeLanguage.dart, nestedRoutesMain, fileName: 'lib/main.dart'),
      DocHeading('see', '你会看到'),
      DocList([
        '列表里有三件商品。点一件就推入它的详情页，点 AppBar 的返回箭头回到列表。',
        '在浏览器里直接打开 `/#/products/2?ref=mail`：详情页显示 `ref: mail`，返回依然回到列表，因为 URL 生成了栈 `[products, 2]`。',
        '打开 `/#/products/99`：路由能匹配，但 `findProduct` 返回 null，页面会提示没有这件商品。（**完全**匹配不到的 URL 会进入路由的 `errorBuilder`，在[重定向](doc:redirects-and-on-exit)一节介绍。）',
      ]),
      DocHeading('state', '参数从哪里来'),
      DocParagraph(
        'builder 会收到一个 `AdaptiveRouteState`；在页面内部也可以用 `AdaptiveRouteState.of(context)` 拿到。常用字段：`pathParameters`、`queryParameters`、`uri`、`arguments`、`name`。',
      ),
      DocCallout(
        CalloutKind.info,
        '详情页设置了 `leading: BackButton(onPressed: () => AdaptiveRouter.of(context).maybePop())`，与包的示例写法一致。`maybePop` 是“先问一声”的返回：系统返回、浏览器后退和 Escape 调用的也是它。下一页会解释。',
      ),
      DocParagraph('**下一步：**[页面间导航](doc:navigation)。'),
    ],
  ),
  DocId.navigation => const DocPage(
    id: DocId.navigation,
    title: '页面间导航',
    description: '先讲 pushNamed 和 pop，再讲回传结果、命名位置、替换和重置页面栈。',
    blocks: [
      DocCallout(
        CalloutKind.info,
        '在 `AdaptiveRouter.of(context)` 上使用和 Navigator 同名的动词：给商品评分并拿回分数、跳到下一件商品、重置回列表。',
        title: '目标',
      ),
      DocHeading('basics', '已经用过的两个'),
      DocList([
        '`pushNamed(location)` 推入一个页面。参数是 **location**（路径），不是路由名。',
        '`pop([result])` 立即移除栈顶页。`maybePop()` 会先询问（页面的 `PopScope`，再是路由的 `onExit`）——返回按钮应该用它。',
      ]),
      DocParagraph('没有 `push(Route)`：每个页面都必须写进路由表，这样 URL 才能随时完整描述页面栈。'),
      DocHeading('more', '再学三个动词，一次一个'),
      DocTable(
        ['动词', '在本步中的用法'],
        [
          [
            '`await pushNamed<int>(...)` + `pop(stars)`',
            '详情页打开 `/products/:id/reviews` 并等待；评分页调用 `pop(4)`；`Future` 以 `4` 完成。',
          ],
          ['`namedLocation(name, pathParameters:)`', '根据名为 `product` 的路由生成 `/products/2`，不用手工拼路径。'],
          ['`pushReplacementNamed(location)`', '「下一件」替换栈顶页。返回仍然回到列表，而不是上一件商品。'],
          ['`pushNamedAndRemoveUntil(location, (_) => false)`', '「回到列表」按 URL 重建整个栈——登录回跳和深链接用的也是这个调用。'],
        ],
      ),
      DocHeading('code', '完整代码'),
      DocParagraph('路由 `:id` 加上 `name` 和子路由 `reviews`；详情页加了三个按钮；新增 `ReviewsPage`。'),
      DocCode(CodeLanguage.dart, navigationMain, fileName: 'lib/main.dart'),
      DocHeading('see', '你会看到'),
      DocList([
        '详情页 → **Rate this product** → 选择 “4 stars”：回到详情页，按钮变成 “Your rating: 4 stars”。',
        '**Next: Notebook** 替换当前页：URL 变成 `/#/products/2`，返回回到列表。',
        '**Back to the list** 清掉 `/products` 之上的所有页面。',
      ]),
      DocCallout(
        CalloutKind.tip,
        '完整列表（包括 `popAndPushNamed`、`popUntil`、`canPop`、`popFrom`、`maybePopFrom`）见[导航动词](doc:navigation-verbs)。本教程用不到它们。',
      ),
      DocParagraph('**下一步：**[添加 Tab](doc:tabs)。'),
    ],
  ),
  DocId.tabs => const DocPage(
    id: DocId.tabs,
    title: '添加 Tab',
    description: '用 AdaptiveShellRoute 包住路由，每个 Tab 一个 AdaptiveBranch。',
    blocks: [
      DocCallout(
        CalloutKind.info,
        '添加「商品」和「账户」两个 Tab。每个 Tab 保留自己的栈；手机上是底部 `NavigationBar`，宽一些的窗口是 `NavigationRail`。',
        title: '目标',
      ),
      DocHeading('concepts', '三个新类型'),
      DocTable(
        ['类型', '作用'],
        [
          [
            '`AdaptiveShellRoute`',
            'Tab 外面的应用框架。**每个应用一个，且只能放在顶层。**它的 `builder(context, shell, child)` 返回你的框架，`child`（当前 Tab）放在里面。双栏布局也是由它启用的。',
          ],
          ['`AdaptiveBranch`', '一个 Tab：一组 `routes`，拥有独立的页面栈。'],
          [
            '`AdaptiveShellState`',
            '即参数 `shell`：`currentIndex`、`goBranch(index)`，以及宽度档位 `isCompact`、`isMedium`、`isExpanded`。',
          ],
        ],
      ),
      DocParagraph(
        'compact 宽度下用 **`AdaptiveShellChrome`** 包住 Tab，并以 builder 形式传入底栏。这样底栏位于 Tab 页面内部，推入的页面（以及底部弹层）就能盖住它。',
      ),
      DocHeading('code', '完整代码'),
      DocParagraph('`/products` 路由原封不动地移进第一个分支；第二个分支放 `/account`；新增的 `AppShell` 负责绘制导航栏。'),
      DocCode(CodeLanguage.dart, tabsMain, fileName: 'lib/main.dart'),
      DocHeading('see', '你会看到'),
      DocList([
        '手机宽度：底部导航栏。打开一件商品，切到 **Account**，再切回来——商品详情还在。每个分支都记得自己的栈。',
        '已经在「商品」Tab 时再点一次它：`goBranch(index, initialLocation: true)` 让该 Tab 回到第一页。',
        '手机上，推入到 Tab 根页之上的页面会隐藏底栏（`AdaptiveRoute.hidesBottomBarWhenPushed`，默认 `true`）。',
        '把窗口拉宽到 600 像素以上：侧边导航栏取代底栏。',
        '再拉宽到 840 像素以上并打开一件商品……列表和详情**并排**出现。你没有为此写任何代码——下一页会解释。',
      ]),
      DocCallout(CalloutKind.warning, '使用 `AdaptiveShellChrome` 时不要再设置 `Scaffold.bottomNavigationBar`，一个底栏就够了。'),
      DocParagraph('**下一步：**[双栏与断点](doc:two-columns)。'),
    ],
  ),
  DocId.twoColumns => const DocPage(
    id: DocId.twoColumns,
    title: '双栏与断点',
    description: '840 像素处发生了什么、页面如何滑动、右栏为空时显示什么、分隔条怎么用。',
    blocks: [
      DocCallout(CalloutKind.info, '弄懂上一步“白送”的双栏模式，并为空着的右栏设置占位页。', title: '目标'),
      DocHeading('bands', '宽度档位'),
      DocParagraph('断点看的是**窗口宽度**，而不是设备类型：'),
      DocTable(
        ['窗口宽度', '档位', '外壳显示'],
        [
          ['< 600（`compactMaxWidth`）', 'compact', '一栏：经典的 `Navigator`'],
          ['600 – 839', 'medium', '仍是一栏；你的框架可以通过 `shell.isMedium` 调整'],
          ['≥ 840（`expandedMinWidth`）', 'expanded', '两栏：栈中的**最后两页**'],
        ],
      ),
      DocHeading('sliding', '页面如何移动'),
      DocList([
        '栈为 `[products]`：左边是列表，右边是**占位页**。',
        '`pushNamed(\'/products/1\')` → `[products, 1]`：详情填进右栏。',
        '再推入 `reviews` → `[products, 1, reviews]`：整体向左滑一栏，详情到了左边，评分页在右边。',
        '返回时再滑回来。拖动两栏之间的分隔条可以调整宽度（左栏初始占 40%，两边都至少保留 35%）。',
      ], ordered: true),
      DocHeading('code', '完整代码'),
      DocParagraph('只改了 `AdaptiveShellRoute`：显式写出 `breakpoints`（840 是默认值，想换别的值时再写），并加上 `placeholder`。'),
      DocCode(CodeLanguage.dart, twoColumnsMain, fileName: 'lib/main.dart'),
      DocHeading('see', '你会看到'),
      DocList([
        '宽 1200 像素时：左边是商品列表，右边是 “Pick a product”。点一件商品：它出现在右栏，列表仍然可见。',
        '给它评分：详情滑到左栏，评分页出现在右栏。',
        '把窗口缩到 840 以下：同一个栈改为一栏显示，只显示栈顶页。再拉宽：恢复两栏。',
        '也可以为每个 Tab 单独设置占位页：`AdaptiveBranch(placeholder: ...)` 优先于外壳级的设置。',
      ]),
      DocCallout(
        CalloutKind.warning,
        '跨越 840 会**重建**页面 `State`（Navigator 树和分栏树是两棵不同的 Widget 树）。不能丢的数据请放进 URL、signal 或状态存储，而不只是 `State` 的字段里。',
      ),
      DocParagraph('**下一步：**[标题与面包屑](doc:titles-and-breadcrumbs)。'),
    ],
  ),
  DocId.titlesBreadcrumbs => const DocPage(
    id: DocId.titlesBreadcrumbs,
    title: '标题与面包屑',
    description: '给路由加上标题，让双栏上方的面包屑显示当前位置。',
    blocks: [
      DocCallout(CalloutKind.info, '在两栏上方显示 “Products › Coffee mug › Rate”，点击其中一节即可跳回。', title: '目标'),
      DocHeading('title', '路由标题'),
      DocParagraph(
        '`AdaptiveRoute.title` 的类型是 `String Function(AdaptiveRouteState state)`。它**在路由匹配时只执行一次**，没有 `BuildContext`——请从 `state.pathParameters` 或 `state.uri` 推导标题。',
      ),
      DocParagraph('双栏模式下，外壳会在两栏上方绘制 `AdaptiveBreadcrumbs`（`showBreadcrumbs: true` 为默认值）。点击前面的某一节会返回到那一页。'),
      DocHeading('code', '完整代码'),
      DocParagraph('每条路由都加上 `title`；详情页标题根据 id 查出来。'),
      DocCode(CodeLanguage.dart, titlesMain, fileName: 'lib/main.dart'),
      DocHeading('see', '你会看到'),
      DocList([
        '宽窗口下依次打开 Coffee mug 和 Rate：面包屑显示 **Products › Coffee mug › Rate**。',
        '点击面包屑里的 **Products**：回到列表。',
        '窗口窄于 840 时没有面包屑——一栏模式下 AppBar 标题就够了。',
      ]),
      DocHeading('async', '稍后才知道的标题'),
      DocParagraph(
        '如果标题要加载后才能确定（或需要 `BuildContext`，例如做国际化），就在页面里设置。`AdaptivePaneScope.maybeOf(context)` 只在分栏内部不为 null：',
      ),
      DocCode(CodeLanguage.dart, '''
// 例如在 didChangeDependencies 中，或数据加载完成之后：
AdaptivePaneScope.maybeOf(context)?.title.value = product.name;'''),
      DocList([
        '静态 `title` 不会在语言切换时重新计算；标题需要跟随实时语言切换时，请在页面里赋值。',
        '想在 `title` 里做不依赖 context 的国际化，可以用 gen-l10n 的 `lookupAppLocalizations(locale)` 或 `Intl.defaultLocale`。',
        '用 `breadcrumbsBuilder` 改样式（见[自定义 UI](doc:customizing-ui)），或用 `showBreadcrumbs: false` 关闭。',
      ]),
      DocParagraph('**下一步：**[重定向、登录与 onExit](doc:redirects-and-on-exit)。'),
    ],
  ),
  DocId.redirectsOnExit => const DocPage(
    id: DocId.redirectsOnExit,
    title: '重定向、登录与 onExit',
    description: '用 redirect 把页面放到登录之后，登录完再送回原处；离开未保存的编辑前先确认。',
    blocks: [
      DocCallout(CalloutKind.info, '让 `/account/profile` 必须登录，登录后回到那里；离开改过的资料页时询问“放弃修改？”。', title: '目标'),
      DocHeading('redirect', 'redirect'),
      DocList([
        '`AdaptiveRouter.redirect` 在每次导航前执行；`AdaptiveRoute.redirect` 只对单条路由生效。两者都是 `(context, state) => FutureOr<String?>`：返回一个 location 就改去那里，返回 `null` 则继续。',
        '重定向链超过 `redirectLimit`（5）次会停止并显示 `errorBuilder`——与匹配不到路由的 URL 用的是同一个页面。',
        '登录状态变化后调用 `router.refresh()`，对当前位置重新执行 redirect。',
      ]),
      DocHeading('fullscreen', '全屏的登录路由'),
      DocParagraph('声明在外壳**之外**（或设置了 `fullscreen: true`）的路由显示在根 `Navigator` 上，任何宽度下都盖住 Tab——适合登录、启动页、引导页。'),
      DocHeading('on-exit', 'onExit'),
      DocParagraph(
        '通过 `maybePop`、返回按钮、系统返回或浏览器后退离开页面前，会先询问 `AdaptiveRoute.onExit`。返回 `false` 就留在原页。`pop`、`pushReplacementNamed` 和 `pushNamedAndRemoveUntil` **不会**询问——与 `Navigator` 一致。',
      ),
      DocParagraph(
        '在分栏内部，对话框要显示在根 Navigator 上才不会被裁剪在栏内：`useRootNavigator: AdaptivePaneScope.maybeOf(context) != null`。',
      ),
      DocHeading('code', '完整代码'),
      DocParagraph('新增：两个保存应用状态的 signal、顶层 `redirect`、外壳之外的 `/login` 路由，以及带 `onExit` 的子路由 `profile`。'),
      DocCode(CodeLanguage.dart, redirectsMain, fileName: 'lib/main.dart'),
      DocHeading('see', '你会看到'),
      DocList([
        '未登录时 Account → **Edit profile**：URL 变成 `/#/login?from=%2Faccount%2Fprofile`，登录页盖住整个界面。',
        '点 **Sign in**：`pushNamedAndRemoveUntil(from, (_) => false)` 重建出栈 `[account, profile]`。',
        '在输入框里打几个字，再点返回：弹出 “Discard changes?”。**Stay** 留在本页，**Discard** 离开。',
        '**Sign out** 并 `refresh()`：下次进入时守卫重新生效。',
      ]),
      DocParagraph('包的示例就是这样保护账户页的——可以对照 `example/lib/router/router_pages.dart`。'),
      DocParagraph('**下一步：**[自定义 UI](doc:customizing-ui)。'),
    ],
  ),
  DocId.customizingUi => const DocPage(
    id: DocId.customizingUi,
    title: '自定义 UI',
    description: '修改分栏、分隔条和面包屑的样式，并添加图片查看器之类的覆盖层路由。',
    blocks: [
      DocCallout(CalloutKind.info, '给教程应用换上卡片式分栏、自定义分隔条和面包屑，并了解覆盖层路由的选项。', title: '目标'),
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
      DocHeading('apply', '用到教程应用里'),
      DocParagraph(
        '在上一步的 `lib/main.dart` 基础上，给 `AdaptiveShellRoute` 加上这些参数（`branches` 保持不变）。这里每个参数都真实存在，代码已用 `flutter analyze` 检查。',
      ),
      DocCode(CodeLanguage.dart, r'''
AdaptiveShellRoute(
  breakpoints: const LayoutBreakpoints(expandedMinWidth: 840),
  showBreadcrumbs: true,
  resizable: true,
  initialLeftPaneFraction: 0.4,
  placeholder: (context) => const Center(child: Text('Pick a product')),
  slideDuration: const Duration(milliseconds: 280),
  resizeHandleBuilder: (context, isHovered) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      height: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: KeyedSubtree(key: const Key('pane-flat'), child: child),
    );
  },
  builder: (context, shell, child) => AppShell(shell: shell, child: child),
  branches: [/* unchanged */],
)'''),
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
      DocCode(CodeLanguage.dart, r'''
// 作为 ':id' 路由的子路由，与 'reviews' 并列。
AdaptiveRoute(
  path: 'photo',
  title: (_) => 'Photo',
  fullscreen: true,
  opaque: false,
  barrierColor: Colors.black,
  barrierDismissible: true,
  transitionDuration: const Duration(milliseconds: 200),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(opacity: animation, child: child);
  },
  builder: (context, state) => const Center(child: Icon(Icons.image, size: 200)),
)'''),
      DocParagraph('在详情页用 `router.pushNamed(\'/products/1/photo\')` 打开。它在任何宽度下都以淡入方式盖住整个窗口；点黑色遮罩即可关闭。'),
      DocParagraph('**下一步：**[读取状态](doc:reading-state)。'),
    ],
  ),
  DocId.readingState => const DocPage(
    id: DocId.readingState,
    title: '读取状态',
    description: '在任意 Widget 中读取当前位置、路由参数、分栏与外壳作用域。',
    blocks: [
      DocCallout(CalloutKind.info, '在任何 Widget 里知道“我在哪儿”：当前位置、参数、是否在分栏里，以及外壳的宽度档位。', title: '目标'),
      DocHeading('cheatsheet', '速查'),
      DocCode(CodeLanguage.dart, '''
AdaptiveRouter.of(context).location.value;               // '/products/1'
AdaptiveRouteState.of(context).pathParameters;           // {'id': '1'}
AdaptivePaneScope.maybeOf(context) != null;              // 是否在双栏的某一栏里
AdaptivePaneScope.maybeOf(context)?.title.value = name;  // 面包屑标题
AdaptiveShellScope.maybeOf(context)?.isExpanded;         // 当前是否双栏'''),
      DocHeading('live', '实时显示当前位置'),
      DocParagraph(
        '路由上的 `location`、`matches`、`currentBranch` 都是 signal。用 `SignalBuilder`（来自 `signals_flutter`）包住读取的地方，每次导航都会自动重建。把下面这段放进教程里 `AccountPage` 的列表试试：',
      ),
      DocCode(CodeLanguage.dart, '''
SignalBuilder(
  builder: (context) => ListTile(
    leading: const Icon(Icons.link),
    title: Text(AdaptiveRouter.of(context).location.value),
  ),
)'''),
      DocHeading('scopes', '分栏与外壳作用域'),
      DocList([
        '`AdaptivePaneScope.maybeOf(context)` 只在双栏的某一栏内部不为 null。用它决定对话框的 `useRootNavigator`，以及设置标题。',
        '`AdaptiveShellScope.maybeOf(context)` 让外壳深处的 Widget 拿到 `AdaptiveShellState`（`currentIndex`、`isCompact`、`isMedium`、`isExpanded`、`goBranch`）。',
      ]),
      DocHeading('chrome', '在自己的框架里绘制标题'),
      DocParagraph(
        '如果想把标题画在内置面包屑以外的地方，读取 `AdaptiveRouter.of(context).matches.value.branchMatches`；每个 match 都有 `title` signal 和 `name`。',
      ),
      DocParagraph('**下一步：**[不用路由只用布局](doc:layout-without-router)。'),
    ],
  ),
  DocId.layoutWithoutRouter => const DocPage(
    id: DocId.layoutWithoutRouter,
    title: '不用路由只用布局',
    description: '只想要滑动分栏时，直接使用 SlidingPaneViewport、SlidingPane 和 AdaptiveBreadcrumbs。',
    blocks: [
      DocCallout(CalloutKind.info, '用你自己维护的页面列表做一个带滑动分栏的文件夹浏览器——没有路由，也没有 URL。', title: '目标'),
      DocParagraph('外壳内部用到的这些 Widget 都是公开的，可以单独使用，例如放在一个已经使用其他路由方案的应用的某个页面里。栈由你自己持有（一个 `List`），变化时重建即可。'),
      DocHeading('code', '完整代码'),
      DocCode(CodeLanguage.dart, layoutWithoutRouterMain, fileName: 'lib/main.dart'),
      DocHeading('see', '你会看到'),
      DocList([
        '宽窗口：左边是 “Home”，右边是 “Open a folder”。逐层打开文件夹，分栏会像路由版本一样滑动。',
        '点面包屑可以把栈截回去；拖动分隔条调整宽度。',
        '窄窗口：`visibleColumnCount` 返回 1，只显示最上层的文件夹；AppBar 的返回箭头会调用 `onPop`。',
      ]),
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
      DocParagraph('教程到此结束。**下一步：**查阅[路由表参考](doc:route-table)。'),
    ],
  ),
  DocId.routeTable => const DocPage(
    id: DocId.routeTable,
    title: '路由表',
    description: 'AdaptiveRouter、AdaptiveRoute、AdaptiveShellRoute、AdaptiveBranch 及各状态对象的参考。',
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
    description: 'AdaptiveRouter 上的全部动词、在一栏与两栏下的行为、切换 Tab 与退出确认。',
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
  DocId.exampleApp => const DocPage(
    id: DocId.exampleApp,
    title: '示例应用导读',
    description: '包内示例应用的组织方式，以及值得按什么顺序阅读。',
    blocks: [
      DocParagraph(
        '`example/` 应用是集成模板：教程里的所有内容，都能在这里看到完整规模的写法。[在线 Demo](https://matkurban.github.io/xue_hua_adaptive_sliding_layout/example/) 的顶栏可以固定为手机 / 折叠屏 / 平板 / 桌面宽度，不用拖动窗口就能看到每个断点。',
      ),
      DocHeading('run', '运行'),
      DocCode(CodeLanguage.shell, '''
cd example
flutter run -d chrome
flutter test'''),
      DocHeading('order', '阅读顺序'),
      DocList([
        '`lib/main.dart`——`MaterialApp.router(routerConfig: RouterPages.router)`，外加宽度预设外壳（`pages/size_preset_screen.dart`）。',
        '`lib/router/router_names.dart`——所有路径和路由名常量。',
        '`lib/router/router_pages.dart`——完整路由表：顶层 `redirect`、外壳之外的登录相关路由、带自定义分隔条 / 面包屑 / 卡片分栏的 `AdaptiveShellRoute`，以及各个分支。',
        '`lib/shell/app_shell.dart`——`AdaptiveShellChrome` + `NavigationBar` 与 `NavigationRail` 的切换、重复点击 Tab、`PopScope` 退出确认。',
        '`lib/pages/…`——各个页面，每个功能区一个目录（见下表）。`lib/services/` 存放它们共享的 signal。',
      ], ordered: true),
      DocHeading('areas', '功能区'),
      DocTable(
        ['功能区', '演示内容', '对应教程', '文件'],
        [
          [
            '登录',
            '全屏的启动 / 登录 / 注册页；访问账户页时 `redirect` 到 `/login?from=`',
            '[重定向](doc:redirects-and-on-exit)',
            '`pages/auth/`',
          ],
          [
            '首页',
            '商品列表 → `/home/:id`，`title` 由 id 解析；用 `transitionsBuilder` 实现半透明全屏看图',
            '[嵌套路由](doc:nested-routes)、[自定义](doc:customizing-ui)',
            '`pages/home/`',
          ],
          ['购物车', '独立的分支，拥有自己的栈', '[Tab](doc:tabs)', '`pages/shopping_cart/`'],
          [
            '联系人',
            '列表 → `/contacts/:id` → `edit`；`onExit` 确认对话框，借助 `AdaptivePaneScope` 选择 `useRootNavigator`',
            '[onExit](doc:redirects-and-on-exit)',
            '`pages/contacts/`',
          ],
          [
            '我的',
            '嵌套的 `theme` / `account` 页；`about` 以 `fullscreenDialog` 打开',
            '[自定义](doc:customizing-ui)',
            '`pages/mine/`',
          ],
          [
            '外壳',
            '底栏与侧栏切换、`goBranch(i, initialLocation: true)`、`PopScope` 退出确认',
            '[Tab](doc:tabs)',
            '`shell/app_shell.dart`',
          ],
        ],
      ),
      DocHeading('try', '在 Demo 里试试'),
      DocList([
        '桌面预设 → 联系人 → 某个联系人 → 编辑：三层页面、两栏、面包屑。',
        '在备注里输入内容后按 Escape：弹出 `onExit` 对话框。',
        '未登录时进入 我的 → 账户：被重定向到登录页，登录后再回来。',
        '打开某个详情页，在手机和桌面预设之间切换。',
      ]),
    ],
  ),
  DocId.migratingGoRouter => const DocPage(
    id: DocId.migratingGoRouter,
    title: '从 go_router 迁移',
    description: '面向 go_router 用户的概念与调用对照。',
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
  DocId.skills => const DocPage(
    id: DocId.skills,
    title: 'Skills',
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
