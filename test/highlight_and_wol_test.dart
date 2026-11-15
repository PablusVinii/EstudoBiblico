import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentinela_study/models/user_highlight_model.dart';
import 'package:sentinela_study/services/highlight_storage_service.dart';
import 'package:sentinela_study/services/wol_search_service.dart';
import 'package:sentinela_study/widgets/highlight_text_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserHighlight Model Tests', () {
    test('Possui exatamente as 6 cores canônicas do JW Library', () {
      expect(UserHighlight.officialColors.length, 6);
      expect(UserHighlight.officialColors[1], const Color(0xFFFFF37A)); // Amarelo
      expect(UserHighlight.officialColors[2], const Color(0xFFB7E492)); // Verde
      expect(UserHighlight.officialColors[3], const Color(0xFF9FB9E3)); // Azul
      expect(UserHighlight.officialColors[4], const Color(0xFFC1A7E2)); // Roxo
      expect(UserHighlight.officialColors[5], const Color(0xFFF698BC)); // Rosa
      expect(UserHighlight.officialColors[6], const Color(0xFFFFBA8A)); // Laranja
    });

    test('Serialização e desserialização toMap e fromMap preserva todos os campos', () {
      final hl = UserHighlight(
        id: 'hl_123',
        sourceType: 'sentinela',
        referenceKey: 'sentinela_w2601_1',
        blockIndex: 4,
        startOffset: 10,
        endOffset: 45,
        colorIndex: 2,
        selectedText: 'Texto destacado oficial',
        noteText: 'Minha anotação de estudo',
        updatedAt: '2026-03-01T12:00:00Z',
      );

      final map = hl.toMap();
      final restored = UserHighlight.fromMap(map);

      expect(restored.id, hl.id);
      expect(restored.sourceType, hl.sourceType);
      expect(restored.referenceKey, hl.referenceKey);
      expect(restored.blockIndex, hl.blockIndex);
      expect(restored.startOffset, hl.startOffset);
      expect(restored.endOffset, hl.endOffset);
      expect(restored.colorIndex, hl.colorIndex);
      expect(restored.selectedText, hl.selectedText);
      expect(restored.noteText, hl.noteText);
      expect(restored.updatedAt, hl.updatedAt);
    });

    test('copyWith cria nova instância imutável com campos alterados', () {
      final hl = UserHighlight(
        id: 'hl_orig',
        sourceType: 'bible',
        referenceKey: 'bible_40_5',
        blockIndex: 3,
        startOffset: 0,
        endOffset: 20,
        colorIndex: 1,
        selectedText: 'Felizes os pobres em espírito',
        updatedAt: '2026-01-01',
      );

      final updated = hl.copyWith(
        colorIndex: 4,
        noteText: 'Comentário sobre humildade',
      );

      expect(updated.id, 'hl_orig');
      expect(updated.colorIndex, 4);
      expect(updated.noteText, 'Comentário sobre humildade');
      expect(hl.colorIndex, 1); // Original inalterado (imutabilidade)
      expect(hl.noteText, isNull);
    });
  });

  group('HighlightStorageService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Salva, carrega, atualiza nota e deleta marcação offline com sucesso', () async {
      const srcType = 'sentinela';
      const refKey = 'w2601_art1';

      // 1. Inicialmente vazio
      var list = await HighlightStorageService.loadHighlights(
        sourceType: srcType,
        referenceKey: refKey,
      );
      expect(list, isEmpty);

      // 2. Salva duas marcações
      final hl1 = UserHighlight(
        id: 'h1',
        sourceType: srcType,
        referenceKey: refKey,
        blockIndex: 2,
        startOffset: 5,
        endOffset: 25,
        colorIndex: 1,
        selectedText: 'Segundo parágrafo',
        updatedAt: '2026-03-01T10:00:00Z',
      );

      final hl2 = UserHighlight(
        id: 'h2',
        sourceType: srcType,
        referenceKey: refKey,
        blockIndex: 1,
        startOffset: 0,
        endOffset: 15,
        colorIndex: 3,
        selectedText: 'Primeiro parágrafo',
        updatedAt: '2026-03-01T10:05:00Z',
      );

      await HighlightStorageService.saveHighlight(hl1);
      await HighlightStorageService.saveHighlight(hl2);

      // 3. Carrega ordenado por blockIndex
      list = await HighlightStorageService.loadHighlights(
        sourceType: srcType,
        referenceKey: refKey,
      );
      expect(list.length, 2);
      expect(list.first.id, 'h2'); // blockIndex 1 vem antes de blockIndex 2
      expect(list.last.id, 'h1');

      // 4. Atualiza nota
      await HighlightStorageService.updateHighlightNote(
        'h1',
        'Nota adicionada com sucesso',
        sourceType: srcType,
        referenceKey: refKey,
      );

      list = await HighlightStorageService.loadHighlights(
        sourceType: srcType,
        referenceKey: refKey,
      );
      final updatedH1 = list.firstWhere((h) => h.id == 'h1');
      expect(updatedH1.noteText, 'Nota adicionada com sucesso');

      // 5. Deleta uma marcação
      await HighlightStorageService.deleteHighlight(
        'h2',
        sourceType: srcType,
        referenceKey: refKey,
      );

      list = await HighlightStorageService.loadHighlights(
        sourceType: srcType,
        referenceKey: refKey,
      );
      expect(list.length, 1);
      expect(list.first.id, 'h1');
    });
  });

  group('HighlightTextHelper Tests', () {
    test('Divide o texto corretamente em spans normais e destacados', () {
      const fullText = 'Jeová criou os humanos com necessidades básicas.';
      final highlights = [
        UserHighlight(
          id: 'test_h',
          sourceType: 'sentinela',
          referenceKey: 'ref1',
          blockIndex: 1,
          startOffset: 0,
          endOffset: 5, // 'Jeová'
          colorIndex: 1,
          selectedText: 'Jeová',
          updatedAt: '',
        ),
      ];

      final spans = HighlightTextHelper.buildHighlightedSpans(
        fullText: fullText,
        highlights: highlights,
      );

      expect(spans.isNotEmpty, true);
      // Primeiro span deve ser o destacado 'Jeová'
      final firstSpan = spans.first as TextSpan;
      expect(firstSpan.text, 'Jeová');
      expect(firstSpan.style?.backgroundColor, isNotNull);

      // Segundo span deve ser o restante do texto sem marcação
      final secondSpan = spans[1] as TextSpan;
      expect(secondSpan.text, ' criou os humanos com necessidades básicas.');
      expect(secondSpan.style?.backgroundColor, isNull);
    });
  });

  group('WolSearchService Tests', () {
    test('Retorna lista vazia imediatamente para queries em branco ou vazias', () async {
      final res1 = await WolSearchService.search(query: '');
      expect(res1, isEmpty);

      final res2 = await WolSearchService.search(query: '   ');
      expect(res2, isEmpty);
    });
  });
}
