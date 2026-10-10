import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/doc_page.dart';
import '../../utils/browser/browser_bridge.dart';
import 'syntax_highlighter.dart';

enum _CopyStatus { idle, copied, failed }

/// Code block with language label, optional file name, static syntax
/// highlighting and a copy button with animated feedback.
class CodeBlock extends StatefulComponent {
  const CodeBlock({required this.code, required this.language, this.fileName, super.key});

  final String code;
  final CodeLanguage language;
  final String? fileName;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  static const _feedbackDuration = Duration(milliseconds: 1800);

  _CopyStatus _status = _CopyStatus.idle;
  Timer? _resetTimer;

  Future<void> _copy() async {
    final ok = await BrowserBridge.copyToClipboard(component.code);
    if (!mounted) return;
    setState(() => _status = ok ? _CopyStatus.copied : _CopyStatus.failed);
    _resetTimer?.cancel();
    _resetTimer = Timer(_feedbackDuration, () {
      if (mounted) setState(() => _status = _CopyStatus.idle);
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final l10n = context.l10n;
    final label = switch (_status) {
      _CopyStatus.idle => l10n.copyCode,
      _CopyStatus.copied => l10n.copied,
      _CopyStatus.failed => l10n.copyFailed,
    };
    final tokens = SyntaxHighlighter.tokenize(component.code, component.language);

    return figure(classes: 'code-block', [
      div(classes: 'code-block__bar', [
        span(classes: 'code-block__lang', [.text(component.language.label)]),
        if (component.fileName case final name?) span(classes: 'code-block__file', [.text(name)]),
        button(
          classes: 'code-block__copy is-${_status.name}',
          type: ButtonType.button,
          attributes: {'aria-live': 'polite', 'aria-label': label},
          onClick: _copy,
          [
            span(
              classes: 'code-block__icon',
              attributes: {'aria-hidden': 'true'},
              [.text(_status == _CopyStatus.copied ? '✓' : '⧉')],
            ),
            span([.text(label)]),
          ],
        ),
      ]),
      pre(classes: 'code-block__pre', [
        code(classes: 'language-${component.language.label}', [
          for (final t in tokens)
            if (t.type == TokenType.plain) .text(t.text) else span(classes: 'tok-${t.type.name}', [.text(t.text)]),
        ]),
      ]),
    ]);
  }
}
