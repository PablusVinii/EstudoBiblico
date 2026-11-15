import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudyStorageService {
  static const String _prefixAns = 'study_ans_';
  static const String _prefixHl = 'study_hl_';
  static const String _prefixDirect = 'study_direct_';
  static const String _prefixAddit = 'study_addit_';
  static const String _prefixAiCache = 'study_ai_cache_';
  static const String _prefixReview = 'study_review_';

  /// Salva persistentemente o comentário/resposta, o trecho destacado e as variantes de comentário
  static Future<void> saveParagraphData({
    required String articleId,
    required int paragraphNumber,
    required String answer,
    String? keyPoint,
    String? directComment,
    String? additionalComment,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ansKey = '$_prefixAns${articleId}_p$paragraphNumber';
    final hlKey = '$_prefixHl${articleId}_p$paragraphNumber';
    final dirKey = '$_prefixDirect${articleId}_p$paragraphNumber';
    final addKey = '$_prefixAddit${articleId}_p$paragraphNumber';

    if (answer.trim().isNotEmpty) {
      await prefs.setString(ansKey, answer.trim());
    } else {
      await prefs.remove(ansKey);
    }

    if (keyPoint != null && keyPoint.trim().isNotEmpty) {
      await prefs.setString(hlKey, keyPoint.trim());
    } else {
      await prefs.remove(hlKey);
    }

    if (directComment != null && directComment.trim().isNotEmpty) {
      await prefs.setString(dirKey, directComment.trim());
    } else {
      await prefs.remove(dirKey);
    }

    if (additionalComment != null && additionalComment.trim().isNotEmpty) {
      await prefs.setString(addKey, additionalComment.trim());
    } else {
      await prefs.remove(addKey);
    }
  }

  /// Salva o cache completo do resultado da IA (Skill cost-aware-llm-pipeline)
  static Future<void> saveAiCommentCache({
    required String articleId,
    required int paragraphNumber,
    required String answer,
    required String keyPoint,
    String? directComment,
    String? additionalComment,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefixAiCache${articleId}_p$paragraphNumber';
    final payload = jsonEncode({
      'answer': answer,
      'keyPoint': keyPoint,
      'directComment': directComment ?? '',
      'additionalComment': additionalComment ?? '',
    });
    await prefs.setString(key, payload);
  }

  /// Obtém o cache do resultado da IA para evitar consumo repetido de cotas (tokens)
  static Future<Map<String, String>?> getAiCommentCache({
    required String articleId,
    required int paragraphNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefixAiCache${articleId}_p$paragraphNumber';
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        'answer': map['answer']?.toString() ?? '',
        'keyPoint': map['keyPoint']?.toString() ?? '',
        'directComment': map['directComment']?.toString() ?? '',
        'additionalComment': map['additionalComment']?.toString() ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  /// Carrega todos os comentários e marcações salvos para um determinado artigo
  static Future<Map<int, Map<String, String>>> loadArticleData(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <int, Map<String, String>>{};

    final keys = prefs.getKeys();
    final ansPrefix = '$_prefixAns${articleId}_p';
    final hlPrefix = '$_prefixHl${articleId}_p';
    final dirPrefix = '$_prefixDirect${articleId}_p';
    final addPrefix = '$_prefixAddit${articleId}_p';

    for (final key in keys) {
      if (key.startsWith(ansPrefix)) {
        final pNumStr = key.substring(ansPrefix.length);
        final pNum = int.tryParse(pNumStr);
        if (pNum != null) {
          final val = prefs.getString(key) ?? '';
          result.putIfAbsent(pNum, () => {})['answer'] = val;
        }
      } else if (key.startsWith(hlPrefix)) {
        final pNumStr = key.substring(hlPrefix.length);
        final pNum = int.tryParse(pNumStr);
        if (pNum != null) {
          final val = prefs.getString(key) ?? '';
          result.putIfAbsent(pNum, () => {})['keyPoint'] = val;
        }
      } else if (key.startsWith(dirPrefix)) {
        final pNumStr = key.substring(dirPrefix.length);
        final pNum = int.tryParse(pNumStr);
        if (pNum != null) {
          final val = prefs.getString(key) ?? '';
          result.putIfAbsent(pNum, () => {})['directComment'] = val;
        }
      } else if (key.startsWith(addPrefix)) {
        final pNumStr = key.substring(addPrefix.length);
        final pNum = int.tryParse(pNumStr);
        if (pNum != null) {
          final val = prefs.getString(key) ?? '';
          result.putIfAbsent(pNum, () => {})['additionalComment'] = val;
        }
      }
    }

    return result;
  }

  /// Salva a resposta de uma pergunta de recapitulação (COMO RESPONDERIA?)
  static Future<void> saveReviewAnswer({
    required String articleId,
    required int questionIndex,
    required String answer,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefixReview${articleId}_q$questionIndex';
    if (answer.trim().isNotEmpty) {
      await prefs.setString(key, answer.trim());
    } else {
      await prefs.remove(key);
    }
  }

  /// Carrega as respostas de recapitulação salvas para um artigo
  static Future<Map<int, String>> loadReviewAnswers(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <int, String>{};
    final keys = prefs.getKeys();
    final prefix = '$_prefixReview${articleId}_q';

    for (final key in keys) {
      if (key.startsWith(prefix)) {
        final qNumStr = key.substring(prefix.length);
        final qNum = int.tryParse(qNumStr);
        if (qNum != null) {
          result[qNum] = prefs.getString(key) ?? '';
        }
      }
    }
    return result;
  }
}
