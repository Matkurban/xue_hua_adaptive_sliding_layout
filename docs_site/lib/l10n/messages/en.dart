import '../../models/app_locale.dart';
import '../../models/doc_id.dart';
import '../../models/doc_page.dart';
import '../../models/theme_preference.dart';
import '../app_localizations.dart';

class EnMessages extends AppLocalizations {
  const EnMessages();

  @override
  AppLocale get locale => AppLocale.en;

  @override
  String get siteName => 'XueHua Adaptive Sliding Layout';
  @override
  String get siteTagline => 'One layout, every screen.';
  @override
  String get siteDescription =>
      'Guides and API reference for xue_hua_adaptive_sliding_layout — declarative adaptive routing for Flutter: one route table, a URL-driven page stack and a 1- or 2-column sliding layout.';

  @override
  String get navHome => 'Home';
  @override
  String get navDocs => 'Docs';
  @override
  String get navGithub => 'GitHub';
  @override
  String get openMenu => 'Open navigation';
  @override
  String get closeMenu => 'Close navigation';
  @override
  String get skipToContent => 'Skip to content';
  @override
  String get onThisPage => 'On this page';
  @override
  String get previousPage => 'Previous';
  @override
  String get nextPage => 'Next';
  @override
  String get expandGroup => 'Expand section';
  @override
  String get collapseGroup => 'Collapse section';
  @override
  String docGroup(DocGroup group) => switch (group) {
    DocGroup.gettingStarted => 'Getting Started',
    DocGroup.guides => 'Guides',
    DocGroup.migration => 'Migration',
    DocGroup.reference => 'Reference',
  };

  @override
  String get languageLabel => 'Language';
  @override
  String get toggleTheme => 'Toggle color theme';
  @override
  String themeName(ThemePreference preference) => switch (preference) {
    ThemePreference.system => 'System',
    ThemePreference.light => 'Light',
    ThemePreference.dark => 'Dark',
  };

  @override
  String get copyCode => 'Copy';
  @override
  String get copied => 'Copied!';
  @override
  String get copyFailed => 'Copy failed';

  @override
  String calloutTitle(CalloutKind kind) => switch (kind) {
    CalloutKind.info => 'Note',
    CalloutKind.tip => 'Tip',
    CalloutKind.warning => 'Warning',
    CalloutKind.danger => 'Danger',
  };

  @override
  String get homeHeroBadge => 'Flutter package · v3.4';
  @override
  String get homeHeroTitle => 'One route table. One or two columns.';
  @override
  String get homeHeroSubtitle =>
      'Declarative adaptive routing for Flutter: a URL maps to a page stack, shown as a classic Navigator on narrow windows and as sliding two-column panes on wide ones. Call sites look like Navigator.';
  @override
  String get homeCtaPrimary => 'Get started';
  @override
  String get homeCtaSecondary => 'Live demo';
  @override
  String get homeFeaturesTitle => 'Why this package';
  @override
  List<({String icon, String title, String body})> get homeFeatures => const [
    (
      icon: '🗺️',
      title: 'One route table',
      body:
          'AdaptiveRouter + MaterialApp.router. Every page lives in the table, so the URL can always express the stack.',
    ),
    (
      icon: '🔗',
      title: 'URL is the stack',
      body:
          'Back, deep links and refresh all take the same path. Web uses hash URLs, so GitHub Pages needs no 404 fallback.',
    ),
    (
      icon: '↔️',
      title: '1 or 2 columns',
      body:
          'Below 840 px a Navigator; at or above it the last two pages slide side by side with a resizable sash and breadcrumbs.',
    ),
    (
      icon: '🧭',
      title: 'Navigator verbs',
      body: 'pushNamed, pop, maybePop, pushReplacementNamed… with the same names and signatures as NavigatorState.',
    ),
  ];

  @override
  String get quickStartStepsTitle => 'Up and running in three steps';
  @override
  List<({String title, String body})> get quickStartSteps => const [
    (title: 'Add', body: 'flutter pub add xue_hua_adaptive_sliding_layout'),
    (title: 'Declare', body: 'Describe pages and tabs in one AdaptiveRouter table.'),
    (title: 'Navigate', body: 'AdaptiveRouter.of(context).pushNamed(...) from any page.'),
  ];

  @override
  String get notFoundTitle => 'Page not found';
  @override
  String get notFoundBody => 'The page you are looking for does not exist or has moved.';

  @override
  String footerCopyright(int year) => '© $year XueHua. Documentation released under the MIT license.';
  @override
  String get footerBuiltWith => 'Built with Jaspr';
}
