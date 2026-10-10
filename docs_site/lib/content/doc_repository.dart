import '../models/app_locale.dart';
import '../models/doc_id.dart';
import '../models/doc_page.dart';
import '../models/nav_item.dart';
import 'docs_en.dart' as en;
import 'docs_zh.dart' as zh;

/// Locale-aware access to documentation content and the derived nav tree.
///
/// Content is plain typed Dart (see `docs_en.dart` / `docs_zh.dart`), which
/// gives compile-time checking, zero runtime parsing and identical output on
/// server and client. Each locale file uses an exhaustive `switch` over
/// [DocId], so adding a page without translating it fails to compile.
class DocRepository {
  const DocRepository._(this._pageOf);

  final DocPage Function(DocId id) _pageOf;

  static DocRepository of(AppLocale locale) => switch (locale) {
    AppLocale.en => const DocRepository._(en.page),
    AppLocale.zh => const DocRepository._(zh.page),
  };

  DocPage page(DocId id) => _pageOf(id);

  List<NavGroup> get navigation => [
    for (final group in DocGroup.values)
      NavGroup(group, [for (final id in DocId.inGroup(group)) NavLeaf(id, page(id).title)]),
  ];
}
