import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../models/user_highlight_model.dart';
import '../services/bible_citation_parser.dart';
import 'highlight_text_helper.dart';

/// Renderiza o texto de um parágrafo de A Sentinela com marcações, destaques e citações bíblicas interativas
class StudyParagraphText extends StatelessWidget {
  final StudyParagraph paragraph;
  final List<UserHighlight> highlights;
  final void Function(String citation) onOpenScripture;
  final List<TapGestureRecognizer> scriptureRecognizers;

  const StudyParagraphText({
    super.key,
    required this.paragraph,
    required this.highlights,
    required this.onOpenScripture,
    required this.scriptureRecognizers,
  });

  static String toSuperscript(int number) {
    const superscripts = {
      '0': '\u2070', '1': '\u00B9', '2': '\u00B2', '3': '\u00B3', '4': '\u2074',
      '5': '\u2075', '6': '\u2076', '7': '\u2077', '8': '\u2078', '9': '\u2079',
    };
    return number.toString().split('').map((d) => superscripts[d] ?? d).join();
  }

  static List<InlineSpan> formatTextWithScriptures({
    required String text,
    required void Function(String citation) onOpenScripture,
    required List<TapGestureRecognizer> scriptureRecognizers,
    bool isHighlighted = false,
  }) {
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    final defaultTextStyle = isHighlighted
        ? const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            backgroundColor: Color(0x59FFD54F),
          )
        : null;

    for (final m in BibleCitationParser.citationRegex.allMatches(text)) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, m.start),
          style: defaultTextStyle,
        ));
      }

      final matchedText = text.substring(m.start, m.end);
      final parsed = BibleCitationParser.parse(matchedText);

      if (parsed != null) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () => onOpenScripture(matchedText);
        scriptureRecognizers.add(recognizer);

        spans.add(
          TextSpan(
            text: matchedText,
            style: TextStyle(
              color: isHighlighted ? const Color(0xFF90CAF9) : const Color(0xFF8AB4F8),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: isHighlighted ? const Color(0xFF90CAF9) : const Color(0x668AB4F8),
              backgroundColor: isHighlighted ? const Color(0x59FFD54F) : null,
            ),
            recognizer: recognizer,
          ),
        );
      } else {
        spans.add(TextSpan(
          text: matchedText,
          style: defaultTextStyle,
        ));
      }

      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: defaultTextStyle,
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final fullText = paragraph.text;
    final numPrefix = '${toSuperscript(paragraph.number)} ';
    final keyPoint = paragraph.highlightedKeyPoint;

    final pHighlights = highlights.where((h) => h.blockIndex == paragraph.number).toList();
    if (pHighlights.isNotEmpty) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: numPrefix,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF8AB4F8),
              ),
            ),
            ...HighlightTextHelper.buildHighlightedSpans(
              fullText: fullText,
              highlights: pHighlights,
              defaultStyle: const TextStyle(fontSize: 17, height: 1.6, color: Color(0xFFE0E0E0)),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 17, height: 1.6, color: Color(0xFFE0E0E0)),
      );
    }

    if (keyPoint == null || keyPoint.trim().isEmpty) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: numPrefix,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF8AB4F8),
              ),
            ),
            ...formatTextWithScriptures(
              text: fullText,
              onOpenScripture: onOpenScripture,
              scriptureRecognizers: scriptureRecognizers,
            ),
          ],
        ),
        style: const TextStyle(fontSize: 17, height: 1.6, color: Color(0xFFE0E0E0)),
      );
    }

    final String cleanKey = keyPoint.trim().replaceAll(RegExp(r'^[^\w\u00C0-\u00FF]+|[^\w\u00C0-\u00FF]+$'), '');

    int matchIndex = fullText.indexOf(cleanKey);
    int matchLength = cleanKey.length;

    // Busca insensível a maiúsculas e minúsculas
    if (matchIndex == -1) {
      final lowerFull = fullText.toLowerCase();
      final lowerKey = cleanKey.toLowerCase();
      matchIndex = lowerFull.indexOf(lowerKey);
      if (matchIndex != -1) {
        matchLength = cleanKey.length;
      }
    }

    // Busca com expressão regular flexível
    if (matchIndex == -1 && cleanKey.isNotEmpty) {
      try {
        final escapedKey = RegExp.escape(cleanKey).replaceAll(RegExp(r'\s+'), r'\s+');
        final regExp = RegExp(escapedKey, caseSensitive: false);
        final m = regExp.firstMatch(fullText);
        if (m != null) {
          matchIndex = m.start;
          matchLength = m.end - m.start;
        }
      } catch (_) {}
    }

    // Busca por cláusulas se a chave for longa
    if (matchIndex == -1 && cleanKey.length > 20) {
      final parts = cleanKey.split(RegExp(r'[,;]'));
      for (final part in parts) {
        final pClean = part.trim();
        if (pClean.length > 15) {
          final idx = fullText.toLowerCase().indexOf(pClean.toLowerCase());
          if (idx != -1) {
            matchIndex = idx;
            matchLength = pClean.length;
            break;
          }
        }
      }
    }

    if (matchIndex == -1) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: numPrefix,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF8AB4F8),
              ),
            ),
            ...formatTextWithScriptures(
              text: fullText,
              onOpenScripture: onOpenScripture,
              scriptureRecognizers: scriptureRecognizers,
            ),
          ],
        ),
        style: const TextStyle(fontSize: 17, height: 1.6, color: Color(0xFFE0E0E0)),
      );
    }

    final before = fullText.substring(0, matchIndex);
    final match = fullText.substring(matchIndex, (matchIndex + matchLength).clamp(0, fullText.length));
    final after = fullText.substring((matchIndex + matchLength).clamp(0, fullText.length));

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: numPrefix,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF8AB4F8),
            ),
          ),
          ...formatTextWithScriptures(
            text: before,
            onOpenScripture: onOpenScripture,
            scriptureRecognizers: scriptureRecognizers,
          ),
          ...formatTextWithScriptures(
            text: match,
            onOpenScripture: onOpenScripture,
            scriptureRecognizers: scriptureRecognizers,
            isHighlighted: true,
          ),
          ...formatTextWithScriptures(
            text: after,
            onOpenScripture: onOpenScripture,
            scriptureRecognizers: scriptureRecognizers,
          ),
        ],
      ),
      style: const TextStyle(fontSize: 17, height: 1.6, color: Color(0xFFE0E0E0)),
    );
  }
}
