import '../models/app_locale.dart';
import '../models/doc_id.dart';
import '../models/doc_page.dart';
import '../models/theme_preference.dart';
import 'messages/en.dart';
import 'messages/zh.dart';

/// Type-safe UI string catalogue, modelled after Flutter's generated
/// `AppLocalizations`. Every locale must implement every member, so a
/// missing translation is a compile error rather than a runtime blank.
abstract class AppLocalizations {
  const AppLocalizations();

  /// Exhaustive locale → implementation mapping.
  static AppLocalizations of(AppLocale locale) => switch (locale) {
    AppLocale.en => const EnMessages(),
    AppLocale.zh => const ZhMessages(),
  };

  AppLocale get locale;

  // Site
  String get siteName;
  String get siteTagline;
  String get siteDescription;

  // Navigation
  String get navHome;
  String get navDocs;
  String get navGithub;
  String get openMenu;
  String get closeMenu;
  String get skipToContent;
  String get onThisPage;
  String get previousPage;
  String get nextPage;
  String get expandGroup;
  String get collapseGroup;
  String docGroup(DocGroup group);

  // Common controls
  String get languageLabel;
  String get toggleTheme;
  String themeName(ThemePreference preference);

  // Code block
  String get copyCode;
  String get copied;
  String get copyFailed;

  // Callouts
  String calloutTitle(CalloutKind kind);

  // Home page
  String get homeHeroBadge;
  String get homeHeroTitle;
  String get homeHeroSubtitle;
  String get homeCtaPrimary;
  String get homeCtaSecondary;
  String get homeFeaturesTitle;
  List<({String icon, String title, String body})> get homeFeatures;

  // Quick start page

  // Not found
  String get notFoundTitle;
  String get notFoundBody;

  // Footer
  String footerCopyright(int year);
  String get footerBuiltWith;
}
