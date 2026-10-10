/// Supported locales of the site. Adding a locale = adding an enum value;
/// the compiler then forces a matching [AppLocalizations] implementation.
enum AppLocale {
  en('en', 'English'),
  zh('zh-CN', '简体中文');

  const AppLocale(this.tag, this.nativeName);

  /// BCP-47 language tag, used for `<html lang>` and persistence.
  final String tag;

  /// Name of the language in the language itself (shown in the switcher).
  final String nativeName;

  /// Locale used for SSR and the first client render (hydration safe).
  static const AppLocale fallback = AppLocale.en;

  static AppLocale? fromTag(String? tag) {
    for (final l in values) {
      if (l.tag == tag) return l;
    }
    return null;
  }
}
