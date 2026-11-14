import 'package:shared_preferences/shared_preferences.dart';

class StudyStorageService {
  static const String _prefixAns = 'study_ans_';
  static const String _prefixHl = 'study_hl_';

  /// Salva persistentemente o comentário/resposta e o trecho destacado de um parágrafo
  static Future<void> saveParagraphData({
    required String articleId,
    required int paragraphNumber,
    required String answer,
    String? keyPoint,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ansKey = '$_prefixAns${articleId}_p$paragraphNumber';
    final hlKey = '$_prefixHl${articleId}_p$paragraphNumber';

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
  }

  /// Carrega todos os comentários e marcações salvos para um determinado artigo
  static Future<Map<int, Map<String, String>>> loadArticleData(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <int, Map<String, String>>{};

    final keys = prefs.getKeys();
    final ansPrefix = '$_prefixAns${articleId}_p';
    final hlPrefix = '$_prefixHl${articleId}_p';

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
      }
    }

    return result;
  }
}
