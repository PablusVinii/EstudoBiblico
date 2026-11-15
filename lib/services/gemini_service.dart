import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiResult {
  final String answer;
  final String keyPoint;

  GeminiResult({required this.answer, required this.keyPoint});
}

class ModelDiscoveryResult {
  final String model;
  final String apiVersion;
  final List<String> availableModels;
  final bool isKeyValid;
  final String? errorMessage;

  ModelDiscoveryResult({
    required this.model,
    required this.apiVersion,
    required this.availableModels,
    required this.isKeyValid,
    this.errorMessage,
  });
}

class GeminiService {
  static const String _prefApiKey = 'gemini_api_key';
  static const String _prefActiveModel = 'gemini_active_model';
  static const String _prefApiVersion = 'gemini_api_version';

  // O modelo padrão fixo solicitado pelo usuário é 3.5 flash-lite
  static const String defaultModel = 'gemini-3.5-flash-lite';

  // Lista padrão de fallback ordenada por modelos flash-lite e flash
  static const List<String> defaultCandidateModels = [
    'gemini-3.5-flash-lite',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash-lite',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-2.0-flash-exp',
    'gemini-pro',
  ];

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefApiKey);
  }

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefApiKey, apiKey.trim());
    // Garante que o modelo padrão 3.5 flash-lite permaneça salvo
    await prefs.setString(_prefActiveModel, defaultModel);
  }

  Future<String> getActiveModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefActiveModel) ?? defaultModel;
  }

  Future<void> saveActiveModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefActiveModel, model);
  }

  Future<String> getApiVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefApiVersion) ?? 'v1beta';
  }

  Future<void> saveApiVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefApiVersion, version);
  }

  /// Descobre os modelos permitidos para a chave do usuário consultando o ModelService do Google
  Future<ModelDiscoveryResult> discoverWorkingModel(String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return ModelDiscoveryResult(
        model: defaultModel,
        apiVersion: 'v1beta',
        availableModels: defaultCandidateModels,
        isKeyValid: false,
        errorMessage: 'Chave não informada.',
      );
    }

    String? lastErrorMsg;

    for (final version in ['v1beta', 'v1']) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/$version/models?key=$cleanKey',
        );
        final response = await http.get(uri).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final list = data['models'] as List?;
          if (list != null && list.isNotEmpty) {
            final supported = <String>[];
            for (final item in list) {
              final methods = item['supportedGenerationMethods'] as List?;
              if (methods != null && methods.contains('generateContent')) {
                String name = item['name']?.toString() ?? '';
                if (name.startsWith('models/')) name = name.substring(7);
                supported.add(name);
              }
            }

            if (supported.isNotEmpty) {
              // Prioriza 3.5 flash-lite ou outros flash-lite
              String chosen = supported.firstWhere(
                (m) => m.contains('flash-lite') || m == defaultModel,
                orElse: () => supported.firstWhere(
                  (m) => m.contains('flash'),
                  orElse: () => supported.first,
                ),
              );

              await saveActiveModel(chosen);
              await saveApiVersion(version);

              return ModelDiscoveryResult(
                model: chosen,
                apiVersion: version,
                availableModels: supported,
                isKeyValid: true,
              );
            }
          }
        } else {
          try {
            final err = jsonDecode(response.body);
            lastErrorMsg = err['error']?['message'] ?? 'Erro HTTP ${response.statusCode}';
          } catch (_) {
            lastErrorMsg = 'Erro HTTP ${response.statusCode}';
          }
        }
      } catch (e) {
        lastErrorMsg = e.toString();
      }
    }

    return ModelDiscoveryResult(
      model: defaultModel,
      apiVersion: 'v1beta',
      availableModels: defaultCandidateModels,
      isKeyValid: false,
      errorMessage: lastErrorMsg,
    );
  }

  /// Gera a resposta de estudo usando o modelo padrão (3.5 flash-lite)
  Future<GeminiResult> generateAnswer({
    required String paragraphText,
    required String questionText,
    String? customApiKey,
  }) async {
    final key = customApiKey ?? await getApiKey();
    if (key == null || key.trim().isEmpty) {
      throw Exception('Chave API do Gemini não configurada. Acesse Configurações para inserir.');
    }

    final savedModel = await getActiveModel();
    final savedVersion = await getApiVersion();

    // 1. Tenta prioritariamente com o modelo 3.5 flash-lite (ou o salvo)
    try {
      return await _callGeminiApi(
        apiKey: key,
        apiVersion: savedVersion,
        model: savedModel,
        paragraphText: paragraphText,
        questionText: questionText,
      );
    } catch (firstError) {
      final errStr = firstError.toString();
      // Se não for 404 (not found), propaga o erro imediatamente (ex: cota excedida, erro de formato)
      if (!errStr.contains('404') && !errStr.contains('NOT_FOUND')) {
        rethrow;
      }
    }

    // 2. Se deu 404, faz fallback automático na lista de modelos suportados
    final modelsToTry = <String>{
      defaultModel,
      ...defaultCandidateModels,
    };

    String lastErr = '';

    for (final version in ['v1beta', 'v1']) {
      for (final model in modelsToTry) {
        try {
          final result = await _callGeminiApi(
            apiKey: key,
            apiVersion: version,
            model: model,
            paragraphText: paragraphText,
            questionText: questionText,
          );

          await saveActiveModel(model);
          await saveApiVersion(version);
          return result;
        } catch (e) {
          lastErr = e.toString();
          if (lastErr.contains('404') || lastErr.contains('NOT_FOUND')) {
            continue;
          } else {
            rethrow;
          }
        }
      }
    }

    throw Exception(
      'Não foi possível conectar com o modelo Gemini na sua chave do Google AI Studio.\nDetalhes: $lastErr',
    );
  }


  /// Gera a resposta para uma pergunta de recapitulação (COMO RESPONDERIA?)
  /// baseada em todo o conteúdo do artigo de estudo.
  Future<String> generateReviewAnswer({
    required String articleTitle,
    required String fullArticleText,
    required String questionText,
    String? customApiKey,
  }) async {
    final key = customApiKey ?? await getApiKey();
    if (key == null || key.trim().isEmpty) {
      throw Exception('Chave API do Gemini não configurada. Acesse Configurações para inserir.');
    }

    final savedModel = await getActiveModel();
    final savedVersion = await getApiVersion();

    // 1. Tenta prioritariamente com o modelo ativo
    try {
      return await _callGeminiReviewApi(
        apiKey: key,
        apiVersion: savedVersion,
        model: savedModel,
        articleTitle: articleTitle,
        fullArticleText: fullArticleText,
        questionText: questionText,
      );
    } catch (firstError) {
      final errStr = firstError.toString();
      if (!errStr.contains('404') && !errStr.contains('NOT_FOUND')) {
        rethrow;
      }
    }

    // 2. Se deu 404, faz fallback automático
    final modelsToTry = <String>{
      defaultModel,
      ...defaultCandidateModels,
    };

    String lastErr = '';

    for (final version in ['v1beta', 'v1']) {
      for (final model in modelsToTry) {
        try {
          final result = await _callGeminiReviewApi(
            apiKey: key,
            apiVersion: version,
            model: model,
            articleTitle: articleTitle,
            fullArticleText: fullArticleText,
            questionText: questionText,
          );

          await saveActiveModel(model);
          await saveApiVersion(version);
          return result;
        } catch (e) {
          lastErr = e.toString();
          if (lastErr.contains('404') || lastErr.contains('NOT_FOUND')) {
            continue;
          } else {
            rethrow;
          }
        }
      }
    }

    throw Exception(
      'Não foi possível conectar com o modelo Gemini na sua chave do Google AI Studio.\nDetalhes: $lastErr',
    );
  }

  Future<String> _callGeminiReviewApi({
    required String apiKey,
    required String apiVersion,
    required String model,
    required String articleTitle,
    required String fullArticleText,
    required String questionText,
  }) async {
    final cleanModel = model.startsWith('models/') ? model.substring(7) : model;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/$apiVersion/models/$cleanModel:generateContent?key=$apiKey',
    );

    final promptText = '''
Você é um assistente de estudo bíblico para o estudo de A Sentinela.
O estudante está na seção final do estudo: "COMO RESPONDERIA?" (Perguntas de recapitulação).

ARTIGO DE ESTUDO:
Título: $articleTitle

CONTEÚDO DO ARTIGO:
$fullArticleText

PERGUNTA DE RECAPITULAÇÃO:
$questionText

INSTRUÇÕES:
1. Responda à pergunta de recapitulação com SUAS PRÓPRIAS PALAVRAS de forma clara, bíblica e direta, resumindo o que foi ensinado ao longo do artigo.
2. Seja conciso (de 2 a 4 frases bem estruturadas), ideal para ser comentado na reunião congregacional.
3. REGRA ABSOLUTA - PROIBIDO QUALQUER SAUDAÇÃO OU APRESENTAÇÃO:
NUNCA inclua saudações, cumprimentos, vocativos ou apresentações no início ou no meio da resposta (É TOTALMENTE PROIBIDO usar "Olá, irmãos!", "Irmãos,", "Queridos irmãos,", "Olá!", "Bom dia", "Respondendo:", etc.). Comece a resposta IMEDIATAMENTE com o comentário direto.
4. Retorne APENAS o texto da resposta, sem formatação JSON e sem aspas.
''';

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': promptText}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
      }
    });

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('Erro na API Gemini (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?[0]?['text'] ??
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
        '';

    if (text.toString().trim().isEmpty) {
      final finishReason = data['candidates']?[0]?['finishReason'] ?? 'SEM_RESPOSTA';
      throw Exception('O modelo Gemini não retornou resposta (motivo: $finishReason). Tente novamente.');
    }

    return sanitizeAnswer(text.toString().trim());
  }

  Future<GeminiResult> _callGeminiApi({
    required String apiKey,
    required String apiVersion,
    required String model,
    required String paragraphText,
    required String questionText,
  }) async {
    final cleanModel = model.startsWith('models/') ? model.substring(7) : model;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/$apiVersion/models/$cleanModel:generateContent?key=$apiKey',
    );

    final promptText = '''
Você é um assistente de estudo bíblico para o estudo de A Sentinela.
PERGUNTA DE ESTUDO:
$questionText

PARÁGRAFO:
$paragraphText

INSTRUÇÕES:
1. Responda à pergunta com SUAS PRÓPRIAS PALAVRAS de forma clara, objetiva e direta. Vá DIRETO AO PONTO. Não copie o texto literal do parágrafo na sua resposta.
2. REGRA ABSOLUTA - PROIBIDO QUALQUER SAUDAÇÃO OU APRESENTAÇÃO:
NUNCA inclua saudações, cumprimentos, vocativos ou apresentações no início ou no meio da resposta (É TOTALMENTE PROIBIDO usar "Olá, irmãos!", "Irmãos,", "Queridos irmãos,", "Olá!", "Bom dia", "Boa noite", "Respondendo à pergunta:", etc.). Comece a resposta IMEDIATAMENTE com a explicação direta, sem nenhuma introdução social ou formal.
3. Identifique no parágrafo acima o trecho contínuo exato que serve de base para essa resposta.
4. SUBPERGUNTAS COM (a), (b), (c): Se a PERGUNTA DE ESTUDO contiver subperguntas como "(a)", "(b)" ou "(c)", você DEVE fornecer todas as respostas no mesmo campo "answer", separando CADA UMA por uma quebra de linha dupla e colocando a letra correspondente antes da resposta gerada, exatamente assim:
(a) [Sua resposta direta para a parte a sem nenhuma saudação]

(b) [Sua resposta direta para a parte b sem nenhuma saudação]

(c) [Sua resposta direta para a parte c, se houver]

Retorne EXCLUSIVAMENTE um objeto JSON no formato:
{
  "answer": "Sua resposta com as próprias palavras aqui",
  "keyPoint": "Trecho literal exato presente no parágrafo"
}
''';

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': promptText}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
      }
    });

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('Erro na API Gemini (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?[0]?['text'] ??
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
        '';

    if (text.toString().trim().isEmpty) {
      final finishReason = data['candidates']?[0]?['finishReason'] ?? 'SEM_RESPOSTA';
      throw Exception('O modelo Gemini não retornou resposta (motivo: $finishReason). Tente novamente.');
    }

    return _parseModelResponse(text.toString());
  }

  GeminiResult parseModelResponse(String rawText) => _parseModelResponse(rawText);

  GeminiResult _parseModelResponse(String rawText) {
    String clean = rawText.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
      if (clean.endsWith('```')) {
        clean = clean.substring(0, clean.length - 3);
      }
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
      if (clean.endsWith('```')) {
        clean = clean.substring(0, clean.length - 3);
      }
    }
    clean = clean.trim();

    try {
      final jsonResponse = jsonDecode(clean);
      final rawAnswer = (jsonResponse['answer'] ?? '').toString().trim();
      return GeminiResult(
        answer: sanitizeAnswer(rawAnswer),
        keyPoint: (jsonResponse['keyPoint'] ?? '').toString().trim(),
      );
    } catch (_) {
      final answerMatch = RegExp(r'"answer"\s*:\s*"([^"]+)"').firstMatch(clean);
      final keyPointMatch = RegExp(r'"keyPoint"\s*:\s*"([^"]+)"').firstMatch(clean);

      if (answerMatch != null) {
        return GeminiResult(
          answer: sanitizeAnswer(answerMatch.group(1) ?? clean),
          keyPoint: keyPointMatch?.group(1) ?? '',
        );
      }

      return GeminiResult(
        answer: sanitizeAnswer(clean),
        keyPoint: '',
      );
    }
  }

  /// Sanitiza a resposta removendo saudações, apresentações e vocativos,
  /// garantindo resposta direta e formato correto para subrespostas (a), (b), (c).
  String sanitizeAnswer(String text) {
    var formatted = _formatSubAnswers(text);

    // Se tiver subperguntas como (a), (b), (c), limpa cada bloco individualmente
    final subRegex = RegExp(r'(\([a-d]\))', caseSensitive: false);
    final matches = subRegex.allMatches(formatted).toList();

    if (matches.isEmpty) {
      return _cleanSingleAnswer(formatted);
    }

    // Se for apenas uma ocorrência isolada no meio de uma frase sem início com (a), trata como resposta simples
    if (matches.length == 1 &&
        matches[0].start > 0 &&
        !formatted.trim().startsWith(RegExp(r'^\([a-d]\)', caseSensitive: false))) {
      return _cleanSingleAnswer(formatted);
    }

    final parts = <String>[];

    // Preserva preâmbulo legítimo antes do primeiro marcador (se houver)
    if (matches[0].start > 0) {
      final preamble = formatted.substring(0, matches[0].start).trim();
      final cleanedPreamble = _cleanSingleAnswer(preamble);
      if (cleanedPreamble.isNotEmpty) {
        parts.add(cleanedPreamble);
      }
    }

    for (int i = 0; i < matches.length; i++) {
      final marker = matches[i].group(1)!;
      final startIdx = matches[i].end;
      final endIdx = (i + 1 < matches.length) ? matches[i + 1].start : formatted.length;
      final chunk = formatted.substring(startIdx, endIdx);
      final cleanedChunk = _cleanSingleAnswer(chunk);
      parts.add('$marker $cleanedChunk');
    }

    return parts.join('\n\n');
  }

  /// Remove saudações, apresentações ("Olá, irmãos!", "Irmãos,", etc.) de um trecho de texto
  String _cleanSingleAnswer(String text) {
    var cleaned = text.trim();

    // 1. Remove saudações explícitas (Olá, Oi, Bom dia, Boa tarde, Boa noite, Saudações, etc.)
    // Ex: "Olá, irmãos!", "Olá!", "Bom dia a todos,", "Oi irmãos,"
    cleaned = cleaned.replaceFirst(
      RegExp(
        r'^(?:(?:ol[áa](?![a-zA-Z0-9])|\boi\b|sauda[çc][õo]es\b|bom\s+dia\b|boa\s+tarde\b|boa\s+noite\b)(?:[,\s!.:;\-]+(?:a\s+todos(?:\s+os\s+irm[ãa]os?)?|aos\s+irm[ãa]os|irm[ãa]os?(?:\s+e\s+irm[ãa]s?)?|irm[ãa]s?|amigos?|pessoal))?[,!.:;\-]*\s*|(?:a\s+paz\s*[,!.:;\-]+\s*(?:a\s+todos|aos\s+irm[ãa]os|irm[ãa]os?|irm[ãa]s?)?[,!.:;\-]*\s*))',
        caseSensitive: false,
      ),
      '',
    );

    cleaned = cleaned.trim();

    // 2. Remove vocativos diretos no início: "Irmãos,", "Queridos irmãos!", "Prezados irmãos:", "Irmãos e irmãs,"
    cleaned = cleaned.replaceFirst(
      RegExp(
        r'^(?:(?:queridos?|prezados?|caros?|meus?|nossos?)\s+)?(?:irm[ãa]os?(?:\s+e\s+irm[ãa]s?)?|irm[ãa]s?)\s*[,!.:;\-]+\s*',
        caseSensitive: false,
      ),
      '',
    );

    cleaned = cleaned.trim();

    // 3. Remove introduções como "Respondendo à pergunta:", "Comentando a pergunta:"
    cleaned = cleaned.replaceFirst(
      RegExp(
        r'^(?:(?:respondendo|em\s+resposta|comentando)\s+(?:[àa]|ao|sobre\s+[ao])\s+pergunta\s*[,!.:;\-]*\s*)',
        caseSensitive: false,
      ),
      '',
    );

    cleaned = cleaned.trim();

    // 4. Garante que a primeira letra da resposta seja maiúscula
    if (cleaned.isNotEmpty) {
      final firstChar = cleaned[0].toUpperCase();
      cleaned = firstChar + (cleaned.length > 1 ? cleaned.substring(1) : '');
    }

    return cleaned;
  }

  /// Garante que respostas com (a), (b) e (c) fiquem separadas por quebra de linha no mesmo box
  String _formatSubAnswers(String answer) {
    var formatted = answer.trim();
    // Garante que (b) e (c) comecem em uma nova linha com espaçamento
    formatted = formatted.replaceAllMapped(
      RegExp(r'(?<!\n)\s*(\([b-d]\))', caseSensitive: false),
      (m) => '\n\n${m.group(1)}',
    );
    // Remove quebras triplas
    formatted = formatted.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return formatted;
  }
}
