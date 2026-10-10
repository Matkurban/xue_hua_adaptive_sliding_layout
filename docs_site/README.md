# xue_hua_docs

`xue_hua_adaptive_sliding_layout` 插件的使用教学文档站，基于 **Jaspr 0.23.5 + jaspr_router 0.9.0**，static（SSG）模式。

> 文档正文位于 `lib/content/`（中英文各一份），内容依据插件的 README、CHANGELOG、`lib/` 与 `example/lib` 编写；插件 API 变化时请同步更新。

## 运行

```bash
dart pub global activate jaspr_cli   # 0.23.5
dart pub get
jaspr serve          # 开发：http://localhost:8080，热重载
jaspr build          # 构建：输出 build/jaspr/（每个路由预渲染为 index.html）
dart analyze         # 静态检查（含 jaspr_lints）
```

`build/jaspr` 是纯静态目录，可直接部署到 GitHub Pages / Nginx / Firebase Hosting。

### 部署到子路径（GitHub Pages）

线上地址：<https://matkurban.github.io/xue_hua_adaptive_sliding_layout/docs/>，由仓库的 `.github/workflows/deploy-web.yml` 与 Flutter 示例一起构建发布。

```bash
jaspr build --dart-define=SITE_BASE=/xue_hua_adaptive_sliding_layout/docs
# 产物 build/jaspr/ 整体复制到 Pages 产物的 docs/ 目录（去掉 packages/、.dart_tool/）
```

- `SITE_BASE` 写入 `<base href>`；路由路径始终相对站点根（`/`、`/quick-start`），Jaspr 客户端会自动去掉/补上 base。
- 不设 `SITE_BASE`（本地开发）时，文档页位于 `/docs/<slug>`。
- 站内链接统一用 `AppLink`（渲染相对 href），保证预渲染 HTML 与客户端在子路径下一致；`SITE_ORIGIN` 可覆盖 canonical/OG 域名（默认 `https://matkurban.github.io`）。

## 目录结构

```text
lib/
├── app.dart                 # @client 根组件：L10nProvider → ThemeProvider → AppRouter
├── main.server.dart         # 服务端/预渲染入口（Document、全局 CSS、防闪烁主题脚本）
├── main.client.dart         # 客户端水合入口
├── main.*.options.dart      # Jaspr 生成的配置（等价于旧版 jaspr_options.dart）
├── l10n/                    # app_localizations.dart / l10n_provider.dart / messages/{en,zh}.dart
├── content/                 # 中英文文档正文（类型化 DocBlock）+ DocRepository
├── components/
│   ├── layout/              # SiteShell, Header, Sidebar, Footer, DocLayout, TableOfContents, ResponsiveContainer
│   ├── markdown/            # DocContent（块渲染器）, InlineMarkdown, Callout
│   ├── code/                # CodeBlock（语言标签 + 复制）, SyntaxHighlighter
│   └── common/              # AppLink, LanguageSwitcher, ThemeToggle, SeoHead, SampleNotice
├── pages/                   # HomePage, DocDetailPage, quickStartPage(+QuickStartSteps), NotFoundPage
├── routes/                  # AppPaths（唯一 URL 来源）, AppRouter
├── models/                  # DocId/DocGroup, DocPage/DocBlock, NavGroup, AppLocale, ThemePreference
├── styles/                  # tokens, app_styles（CSS 变量主题）, ThemeProvider
└── utils/                   # storage（localStorage 条件导入）, browser（剪贴板/DOM）, platform（kIsWeb）
```

## 设计决策

1. **国际化**：`AppLocalizations` 抽象类 + 每种语言一个实现，缺翻译即编译失败；`AppLocale` 枚举 + 穷举 `switch` 选择实现。`L10nProvider`（StatefulComponent）+ 私有 `InheritedComponent`，通过 `context.l10n` / `context.docs` / `context.l10nController` 访问，切换只重建依赖方，无刷新。
2. **水合安全**：服务端与客户端首帧统一使用默认 `en`、主题 `system`；在 `addPostFrameCallback` 中读取 localStorage 再 `setState`，属于普通更新而非水合差异。主题的视觉部分由 `<head>` 内联脚本在首次绘制前设置 `html[data-theme]`，CSS 变量 + `prefers-color-scheme` 实现“跟随系统”，零闪烁。
3. **类型安全 / 无魔法字符串**：页面由 `DocId` 枚举驱动（slug、分组、上一页/下一页、路由注册、预渲染都由它派生）；URL 只在 `AppPaths` 生成；存储键在 `StorageKey` 枚举；正文是 sealed `DocBlock`，渲染器穷举匹配。正文内链接写作 `doc:<slug>`，渲染时解析为 `DocId`。
4. **内容用 Dart 而非 Markdown 文件**：零运行时解析、编译期检查、服务端与客户端输出一致。若文档规模增大，可迁移到官方 `jaspr_content`（Markdown + frontmatter）。
5. **组合优于继承**：`DocLayout(sidebar:, toc:, child:)`、`Callout(child:)`、`DocDetailPage(intro:)` 均为插槽；`quickStartPage` 只是注入了“三步上手”插槽的 `const DocDetailPage`（保持各文档路由组件深度一致，客户端导航时 `Document.head` 能正确更新）。抽屉状态通过 `NavDrawerScope` 在 Header 与 DocLayout 间共享，互不依赖。
6. **代码高亮**：自研约 60 行的正则分词器（dart / yaml / bash），在预渲染阶段输出带 class 的 `<span>`。相比 highlight.js CDN：无外部依赖与网络请求、无布局抖动、不会在水合后改写 DOM 导致冲突。扩展语言只需在 `CodeLanguage` 加枚举值并添加规则。复制使用 Clipboard API，非安全上下文降级为 `execCommand`，按钮有 已复制/失败 状态与动画反馈。
7. **路由与 SEO**：单页路由（客户端导航保持语言/主题状态）+ static 模式预渲染每个路由；`SeoHead` 通过 `Document.head` 输出 title、description、OpenGraph、canonical（含部署子路径）。
8. **平台隔离**：浏览器 API 全部经 `utils/` 的条件导入（`dart.library.js_interop`）封装，服务端为 no-op，组件中无平台分支。

## 扩展

- 新增页面：`DocId` 加一个值 → 编译器提示在 `docs_en.dart`/`docs_zh.dart` 补内容，路由/导航/预渲染自动生效。
- 新增语言：`AppLocale` 加值 → 实现一个 `AppLocalizations` 子类与一份 content。
