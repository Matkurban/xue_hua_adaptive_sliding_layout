import 'package:jaspr/jaspr.dart';

import '../content/doc_repository.dart';
import '../models/app_locale.dart';
import '../utils/browser/browser_bridge.dart';
import '../utils/storage/local_storage.dart';
import 'app_localizations.dart';

/// Owns the current [AppLocale] and exposes it through [_L10nScope].
///
/// Hydration safety: the server and the *first* client build both use
/// [AppLocale.fallback] (English), so the hydrated DOM matches the
/// pre-rendered HTML exactly. Only after the first frame do we read the
/// persisted preference and, if different, rebuild — a normal client
/// update, never a hydration mismatch.
class L10nProvider extends StatefulComponent {
  const L10nProvider({required this.child, super.key});

  final Component child;

  @override
  State<L10nProvider> createState() => _L10nProviderState();
}

class _L10nProviderState extends State<L10nProvider> implements L10nController {
  AppLocale _locale = AppLocale.fallback;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      context.binding.addPostFrameCallback(_restorePersistedLocale);
    }
  }

  void _restorePersistedLocale() {
    final stored = AppLocale.fromTag(KeyValueStore.instance.read(StorageKey.locale));
    if (stored != null && stored != _locale) setLocale(stored);
  }

  @override
  AppLocale get locale => _locale;

  @override
  void setLocale(AppLocale locale) {
    if (locale == _locale) return;
    setState(() => _locale = locale);
    KeyValueStore.instance.write(StorageKey.locale, locale.tag);
    BrowserBridge.setRootAttribute('lang', locale.tag);
  }

  @override
  Component build(BuildContext context) {
    return _L10nScope(
      controller: this,
      locale: _locale,
      messages: AppLocalizations.of(_locale),
      docs: DocRepository.of(_locale),
      child: component.child,
    );
  }
}

/// Imperative API for components that change the language.
abstract interface class L10nController {
  AppLocale get locale;
  void setLocale(AppLocale locale);
}

class _L10nScope extends InheritedComponent {
  const _L10nScope({
    required this.controller,
    required this.locale,
    required this.messages,
    required this.docs,
    required super.child,
  });

  final L10nController controller;
  final AppLocale locale;
  final AppLocalizations messages;
  final DocRepository docs;

  static _L10nScope of(BuildContext context) {
    final scope = context.dependOnInheritedComponentOfExactType<_L10nScope>();
    assert(scope != null, 'No L10nProvider found in the component tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(_L10nScope oldComponent) => oldComponent.locale != locale;
}

/// `context.l10n.siteName`, `context.docs.page(DocId.introduction)` …
extension L10nContext on BuildContext {
  AppLocalizations get l10n => _L10nScope.of(this).messages;
  DocRepository get docs => _L10nScope.of(this).docs;
  L10nController get l10nController => _L10nScope.of(this).controller;
}
