import '../../models/doc_page.dart';

/// Token categories → CSS classes `tok-<name>`.
enum TokenType { plain, comment, string, keyword, type, number, annotation, key, punctuation, command, flag }

typedef Token = ({TokenType type, String text});

/// A tiny regex-based tokenizer (≈ 60 lines) for the handful of languages
/// used in the docs. It runs during pre-rendering, so highlighted HTML is
/// shipped statically: no CDN script, no layout shift, no hydration diff.
abstract final class SyntaxHighlighter {
  static List<Token> tokenize(String source, CodeLanguage language) {
    final rules = _rules[language];
    if (rules == null) return [(type: TokenType.plain, text: source)];
    final tokens = <Token>[];
    var pos = 0;
    final buffer = StringBuffer();
    void flush() {
      if (buffer.isNotEmpty) {
        tokens.add((type: TokenType.plain, text: buffer.toString()));
        buffer.clear();
      }
    }

    outer:
    while (pos < source.length) {
      for (final (type, pattern) in rules) {
        final match = pattern.matchAsPrefix(source, pos);
        if (match != null && match.end > pos) {
          flush();
          tokens.add((type: type, text: match[0]!));
          pos = match.end;
          continue outer;
        }
      }
      buffer.write(source[pos]);
      pos++;
    }
    flush();
    return tokens;
  }

  static const _dartKeywords =
      'abstract|as|async|await|break|case|catch|class|const|continue|default|else|enum|export|extends|extension|'
      'false|final|finally|for|if|implements|import|in|is|late|library|mixin|new|null|on|override|part|required|'
      'return|sealed|static|super|switch|this|throw|true|try|typedef|var|void|when|while|with|yield';

  static final Map<CodeLanguage, List<(TokenType, RegExp)>> _rules = {
    CodeLanguage.dart: [
      (TokenType.comment, RegExp(r'//[^\n]*|/\*[\s\S]*?\*/')),
      (
        TokenType.string,
        RegExp(
          r"'''[\s\S]*?'''|"
          r'"""[\s\S]*?"""|'
          r"'(?:\\.|[^'\\\n])*'|"
          r'"(?:\\.|[^"\\\n])*"',
        ),
      ),
      (TokenType.annotation, RegExp(r'@\w+')),
      (TokenType.keyword, RegExp('\\b(?:$_dartKeywords)\\b')),
      (TokenType.type, RegExp(r'\b[A-Z]\w*')),
      (TokenType.number, RegExp(r'\b\d+(?:\.\d+)?\b')),
      (TokenType.punctuation, RegExp(r'[{}()\[\];,.=>:?|]')),
      (TokenType.plain, RegExp(r'\w+')),
    ],
    CodeLanguage.yaml: [
      (TokenType.comment, RegExp(r'#[^\n]*')),
      (TokenType.key, RegExp(r'^[ \t]*-?[ \t]*[\w.\-/]+(?=:)', multiLine: true)),
      (
        TokenType.string,
        RegExp(
          r"'[^'\n]*'|"
          r'"[^"\n]*"',
        ),
      ),
      (TokenType.number, RegExp(r'[\^~]?\d+(?:\.\d+)*(?:[-+][\w.]+)?')),
      (TokenType.keyword, RegExp(r'\b(?:true|false|null|sdk|flutter)\b')),
      (TokenType.punctuation, RegExp(r'[:\-\[\]{}]')),
      (TokenType.plain, RegExp(r'\w+')),
    ],
    CodeLanguage.shell: [
      (TokenType.comment, RegExp(r'#[^\n]*')),
      (TokenType.command, RegExp(r'^[ \t]*[\w.\-/]+', multiLine: true)),
      (TokenType.flag, RegExp(r'\s--?[\w\-]+')),
      (
        TokenType.string,
        RegExp(
          r"'[^'\n]*'|"
          r'"[^"\n]*"',
        ),
      ),
      (TokenType.plain, RegExp(r'\w+')),
    ],
  };
}
