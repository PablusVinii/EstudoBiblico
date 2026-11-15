import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_highlight_model.dart';

/// Serviço responsável pelo armazenamento persistente e offline
/// das marcações de texto e anotações do usuário.
class HighlightStorageService {
  static const String _keyPrefix = 'user_highlights_';

  static String _buildKey(String sourceType, String referenceKey) {
    return '$_keyPrefix${sourceType}_$referenceKey';
  }

  /// Carrega todas as marcações para uma determinada referência (capítulo ou artigo)
  static Future<List<UserHighlight>> loadHighlights({
    required String sourceType,
    required String referenceKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(sourceType, referenceKey);
    final rawList = prefs.getStringList(key) ?? [];

    final result = <UserHighlight>[];
    for (final raw in rawList) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        result.add(UserHighlight.fromMap(map));
      } catch (_) {
        // Ignora entradas corrompidas
      }
    }

    // Ordena pelo bloco e pelo offset de início
    result.sort((a, b) {
      final blockComp = a.blockIndex.compareTo(b.blockIndex);
      if (blockComp != 0) return blockComp;
      return a.startOffset.compareTo(b.startOffset);
    });

    return List.unmodifiable(result);
  }

  /// Salva ou atualiza uma marcação
  static Future<void> saveHighlight(UserHighlight highlight) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(highlight.sourceType, highlight.referenceKey);
    final currentList = await loadHighlights(
      sourceType: highlight.sourceType,
      referenceKey: highlight.referenceKey,
    );

    // Substitui se já existir (mesmo ID) ou adiciona
    final updatedList = currentList.where((h) => h.id != highlight.id).toList();
    updatedList.add(highlight);

    final rawList = updatedList.map((h) => h.toJson()).toList();
    await prefs.setStringList(key, rawList);
  }

  /// Remove uma marcação pelo ID
  static Future<void> deleteHighlight(
    String highlightId, {
    required String sourceType,
    required String referenceKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(sourceType, referenceKey);
    final currentList = await loadHighlights(
      sourceType: sourceType,
      referenceKey: referenceKey,
    );

    final updatedList = currentList.where((h) => h.id != highlightId).toList();
    final rawList = updatedList.map((h) => h.toJson()).toList();
    await prefs.setStringList(key, rawList);
  }

  /// Atualiza apenas o texto da anotação de uma marcação
  static Future<void> updateHighlightNote(
    String highlightId,
    String noteText, {
    required String sourceType,
    required String referenceKey,
  }) async {
    final currentList = await loadHighlights(
      sourceType: sourceType,
      referenceKey: referenceKey,
    );

    final targetIndex = currentList.indexWhere((h) => h.id == highlightId);
    if (targetIndex != -1) {
      final updated = currentList[targetIndex].copyWith(
        noteText: noteText.trim().isNotEmpty ? noteText.trim() : null,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await saveHighlight(updated);
    }
  }

  /// Remove todas as marcações da referência
  static Future<void> clearAllHighlights({
    required String sourceType,
    required String referenceKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildKey(sourceType, referenceKey);
    await prefs.remove(key);
  }
}
