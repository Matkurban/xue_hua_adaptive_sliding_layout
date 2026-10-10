import '../../models/app_locale.dart';
import '../../models/doc_id.dart';
import '../../models/doc_page.dart';
import '../../models/theme_preference.dart';
import '../app_localizations.dart';

class ZhMessages extends AppLocalizations {
  const ZhMessages();

  @override
  AppLocale get locale => AppLocale.zh;

  @override
  String get siteName => '雪花 · 自适应滑动布局';
  @override
  String get siteTagline => '一套布局，适配所有屏幕。';
  @override
  String get siteDescription =>
      'xue_hua_adaptive_sliding_layout 使用指南与 API 参考——面向 Flutter 的声明式自适应路由：一张路由表、由 URL 驱动的页面栈，以及 1 栏 / 2 栏滑动布局。';

  @override
  String get navHome => '首页';
  @override
  String get navDocs => '文档';
  @override
  String get navGithub => 'GitHub';
  @override
  String get openMenu => '打开导航';
  @override
  String get closeMenu => '关闭导航';
  @override
  String get skipToContent => '跳到正文';
  @override
  String get onThisPage => '本页目录';
  @override
  String get previousPage => '上一页';
  @override
  String get nextPage => '下一页';
  @override
  String get expandGroup => '展开分组';
  @override
  String get collapseGroup => '折叠分组';
  @override
  String docGroup(DocGroup group) => switch (group) {
    DocGroup.gettingStarted => '入门',
    DocGroup.tutorial => '教程',
    DocGroup.reference => '参考',
    DocGroup.migration => '迁移',
    DocGroup.ai => 'AI',
  };

  @override
  String get languageLabel => '语言';
  @override
  String get toggleTheme => '切换配色主题';
  @override
  String themeName(ThemePreference preference) => switch (preference) {
    ThemePreference.system => '跟随系统',
    ThemePreference.light => '亮色',
    ThemePreference.dark => '暗色',
  };

  @override
  String get copyCode => '复制';
  @override
  String get copied => '已复制！';
  @override
  String get copyFailed => '复制失败';

  @override
  String calloutTitle(CalloutKind kind) => switch (kind) {
    CalloutKind.info => '说明',
    CalloutKind.tip => '提示',
    CalloutKind.warning => '注意',
    CalloutKind.danger => '危险',
  };

  @override
  String get homeHeroBadge => 'Flutter 插件 · v3.4';
  @override
  String get homeHeroTitle => '一张路由表，一栏或两栏';
  @override
  String get homeHeroSubtitle => '面向 Flutter 的声明式自适应路由：URL 映射成页面栈，窄屏时是经典 Navigator，宽屏时变成可滑动的双栏。调用方式与 Navigator 完全一致。';
  @override
  String get homeCtaPrimary => '快速开始';
  @override
  String get homeCtaSecondary => '在线 Demo';
  @override
  String get homeFeaturesTitle => '为什么选择它';
  @override
  List<({String icon, String title, String body})> get homeFeatures => const [
    (icon: '🗺️', title: '一张路由表', body: 'AdaptiveRouter + MaterialApp.router。所有页面都在表里，URL 总能完整表达页面栈。'),
    (icon: '🔗', title: 'URL 即栈', body: '后退、深链、刷新走同一条路径。Web 使用 hash URL，部署到 GitHub Pages 无需 404 回退。'),
    (icon: '↔️', title: '一栏或两栏', body: '窗口小于 840 时是 Navigator；达到 840 后最后两页并排滑动，支持拖动分割条与面包屑。'),
    (
      icon: '🧭',
      title: 'Navigator 同名动词',
      body: 'pushNamed、pop、maybePop、pushReplacementNamed……名称与签名都和 NavigatorState 一致。',
    ),
  ];

  @override
  String get notFoundTitle => '页面不存在';
  @override
  String get notFoundBody => '你访问的页面不存在或已被移动。';

  @override
  String footerCopyright(int year) => '© $year 雪花。文档基于 MIT 协议发布。';
  @override
  String get footerBuiltWith => '基于 Jaspr 构建';
}
