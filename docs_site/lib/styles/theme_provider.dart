import 'package:jaspr/jaspr.dart';

import '../models/theme_preference.dart';
import '../utils/browser/browser_bridge.dart';
import '../utils/storage/local_storage.dart';

/// Owns the [ThemePreference].
///
/// Visual theming itself is pure CSS (custom properties keyed on
/// `html[data-theme]` + `prefers-color-scheme`), and an inline head script
/// (see [themeBootScript]) applies the stored preference *before first
/// paint* — so there is no flash and no hydration mismatch. This component
/// only tracks the preference for UI (toggle icon) and persists changes;
/// like L10nProvider it starts at [ThemePreference.system] on both server
/// and first client render and syncs after mount.
class ThemeProvider extends StatefulComponent {
  const ThemeProvider({required this.child, super.key});

  final Component child;

  @override
  State<ThemeProvider> createState() => _ThemeProviderState();
}

class _ThemeProviderState extends State<ThemeProvider> implements ThemeController {
  ThemePreference _preference = ThemePreference.system;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      context.binding.addPostFrameCallback(() {
        final stored = ThemePreference.fromStorage(KeyValueStore.instance.read(StorageKey.theme));
        if (stored != _preference) setState(() => _preference = stored);
      });
    }
  }

  @override
  ThemePreference get preference => _preference;

  @override
  void setPreference(ThemePreference preference) {
    setState(() => _preference = preference);
    KeyValueStore.instance.write(StorageKey.theme, preference.storageValue);
    BrowserBridge.setRootAttribute(themeAttribute, preference.dataThemeAttribute);
  }

  @override
  Component build(BuildContext context) =>
      _ThemeScope(controller: this, preference: _preference, child: component.child);
}

abstract interface class ThemeController {
  ThemePreference get preference;
  void setPreference(ThemePreference preference);
}

class _ThemeScope extends InheritedComponent {
  const _ThemeScope({required this.controller, required this.preference, required super.child});

  final ThemeController controller;
  final ThemePreference preference;

  @override
  bool updateShouldNotify(_ThemeScope oldComponent) => oldComponent.preference != preference;
}

extension ThemeContext on BuildContext {
  ThemeController get theme {
    final scope = dependOnInheritedComponentOfExactType<_ThemeScope>();
    assert(scope != null, 'No ThemeProvider found in the component tree.');
    return scope!.controller;
  }
}

const String themeAttribute = 'data-theme';

/// Runs synchronously in `<head>` before the body is parsed.
final String themeBootScript =
    "(function(){try{var t=localStorage.getItem('${StorageKey.theme.key}');"
    "if(t==='${ThemePreference.light.storageValue}'||t==='${ThemePreference.dark.storageValue}')"
    "{document.documentElement.setAttribute('$themeAttribute',t);}"
    "}catch(e){}})();";
