/// User theme preference. [system] follows `prefers-color-scheme`.
enum ThemePreference {
  system('system'),
  light('light'),
  dark('dark');

  const ThemePreference(this.storageValue);

  final String storageValue;

  /// Value of the `data-theme` attribute on `<html>`; `null` = follow system.
  String? get dataThemeAttribute => this == system ? null : storageValue;

  /// Cycle order used by the toggle button.
  ThemePreference get next => values[(index + 1) % values.length];

  static ThemePreference fromStorage(String? value) {
    for (final p in values) {
      if (p.storageValue == value) return p;
    }
    return system;
  }
}
