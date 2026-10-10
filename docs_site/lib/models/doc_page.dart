import 'doc_id.dart';

/// Languages supported by the code highlighter.
enum CodeLanguage {
  dart('dart'),
  yaml('yaml'),
  shell('bash'),
  plain('text');

  const CodeLanguage(this.label);
  final String label;
}

enum CalloutKind { info, tip, warning, danger }

/// Strongly typed content blocks. The renderer switches exhaustively over
/// this sealed hierarchy, so adding a block type is a compile-time checked
/// change. Text fields support a tiny inline-markdown subset
/// (`code`, **bold**, [link](url)).
sealed class DocBlock {
  const DocBlock();
}

final class DocHeading extends DocBlock {
  const DocHeading(this.anchor, this.text, {this.level = 2});
  final String anchor;
  final String text;
  final int level; // 2 or 3 — h1 is the page title.
}

final class DocParagraph extends DocBlock {
  const DocParagraph(this.text);
  final String text;
}

final class DocCode extends DocBlock {
  const DocCode(this.language, this.code, {this.fileName});
  final CodeLanguage language;
  final String code;
  final String? fileName;
}

final class DocCallout extends DocBlock {
  const DocCallout(this.kind, this.text, {this.title});
  final CalloutKind kind;
  final String text;
  final String? title;
}

final class DocList extends DocBlock {
  const DocList(this.items, {this.ordered = false});
  final List<String> items;
  final bool ordered;
}

final class DocTable extends DocBlock {
  const DocTable(this.header, this.rows);
  final List<String> header;
  final List<List<String>> rows;
}

class DocPage {
  const DocPage({required this.id, required this.title, required this.description, required this.blocks});

  final DocId id;
  final String title;
  final String description;
  final List<DocBlock> blocks;

  /// Table of contents derived from headings — never maintained by hand.
  List<DocHeading> get toc => blocks.whereType<DocHeading>().toList();
}
