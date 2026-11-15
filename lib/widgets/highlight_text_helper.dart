import 'package:flutter/material.dart';
import '../models/user_highlight_model.dart';

/// Utilitário puro e reutilizável para fatiamento e renderização de textos com realces de usuário
class HighlightTextHelper {
  /// Divide um texto em uma lista de [InlineSpan], aplicando as cores de destaque
  /// para todas as marcações do usuário salvas naquele bloco.
  static List<InlineSpan> buildHighlightedSpans({
    required String fullText,
    required List<UserHighlight> highlights,
    TextStyle? defaultStyle,
    TextStyle? targetStyle,
    bool isTarget = false,
  }) {
    if (highlights.isEmpty) {
      return [
        TextSpan(
          text: fullText,
          style: isTarget ? targetStyle : defaultStyle,
        ),
      ];
    }

    // Ordena as marcações pelo offset de início
    final sorted = List<UserHighlight>.from(highlights)
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));

    final spans = <InlineSpan>[];
    int currentPos = 0;

    for (final h in sorted) {
      int start = h.startOffset;
      int end = h.endOffset;

      // Se os offsets não baterem perfeitamente com o texto atual, busca pelo selectedText
      if (start < currentPos ||
          start >= fullText.length ||
          end > fullText.length ||
          fullText.substring(start, end) != h.selectedText) {
        final matchIdx = fullText.indexOf(h.selectedText, currentPos);
        if (matchIdx != -1) {
          start = matchIdx;
          end = start + h.selectedText.length;
        } else {
          continue; // Pula se não encontrar o trecho
        }
      }

      // Adiciona texto anterior sem marcação
      if (start > currentPos) {
        spans.add(TextSpan(
          text: fullText.substring(currentPos, start),
          style: isTarget ? targetStyle : defaultStyle,
        ));
      }

      // Adiciona o trecho destacado com a cor oficial
      final baseStyle = isTarget ? (targetStyle ?? defaultStyle) : defaultStyle;
      spans.add(TextSpan(
        text: fullText.substring(start, end),
        style: (baseStyle ?? const TextStyle()).copyWith(
          backgroundColor: h.highlightColor,
          fontWeight: FontWeight.w500,
        ),
      ));

      currentPos = end;
    }

    // Adiciona o restante do texto após o último destaque
    if (currentPos < fullText.length) {
      spans.add(TextSpan(
        text: fullText.substring(currentPos),
        style: isTarget ? targetStyle : defaultStyle,
      ));
    }

    return spans;
  }
}
