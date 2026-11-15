import 'dart:convert';
import 'package:http/http.dart' as http;
import 'gemini_service.dart';
import 'wol_search_service.dart';

/// Resultado estruturado da explicação bíblica oficial gerada por IA (RAG)
class AiExplanationResult {
  final String explanation;
  final String? application;
  final String? officialSource;
  final List<WolSearchResult> sources;

  const AiExplanationResult({
    required this.explanation,
    this.application,
    this.officialSource,
    this.sources = const [],
  });
}

/// Serviço responsável pelo pipeline RAG de explicação bíblica confinada
/// estritamente às publicações oficiais de jw.org e wol.jw.org.
class AiExplanationService {
  final GeminiService _geminiService;

  AiExplanationService({GeminiService? geminiService})
      : _geminiService = geminiService ?? GeminiService();

  /// Explica um trecho ou versículo combinando pesquisa no wol.jw.org com síntese do Gemini
  Future<AiExplanationResult> explainSelection({
    required String selectedText,
    required String contextText,
    String? customApiKey,
  }) async {
    final apiKey = customApiKey ?? await _geminiService.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('Chave API do Gemini não configurada. Acesse Configurações.');
    }

    // 1. Pesquisa trechos no wol.jw.org em tempo real (RAG)
    List<WolSearchResult> wolResults = [];
    try {
      wolResults = await WolSearchService.search(query: selectedText, maxResults: 3);
    } catch (_) {
      // Continua com contexto local se a busca on-line falhar
    }

    final activeModel = await _geminiService.getActiveModel();
    final apiVersion = await _geminiService.getApiVersion();

    return await _callGroundedGemini(
      apiKey: apiKey,
      apiVersion: apiVersion,
      model: activeModel,
      selectedText: selectedText,
      contextText: contextText,
      wolResults: wolResults,
    );
  }

  Future<AiExplanationResult> _callGroundedGemini({
    required String apiKey,
    required String apiVersion,
    required String model,
    required String selectedText,
    required String contextText,
    required List<WolSearchResult> wolResults,
  }) async {
    final cleanModel = model.startsWith('models/') ? model.substring(7) : model;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/$apiVersion/models/$cleanModel:generateContent?key=$apiKey',
    );

    final wolContextBuffer = StringBuffer();
    if (wolResults.isNotEmpty) {
      for (final r in wolResults) {
        wolContextBuffer.writeln('- Artigo: ${r.title} (${r.publication})');
        wolContextBuffer.writeln('  URL: ${r.url}');
      }
    } else {
      wolContextBuffer.writeln('Nenhum trecho on-line específico retornado; use o contexto local do parágrafo/artigo.');
    }

    final promptText = '''
Você é um assistente de pesquisa bíblica para estudantes das Testemunhas de Jeová.
Sua função é explicar o termo ou versículo bíblico fornecido com base ESTRITAMENTE nas publicações oficiais da Torre de Vigia (disponíveis em jw.org e wol.jw.org).

TERMO OU VERSÍCULO SELECIONADO:
"$selectedText"

CONTEXTO DO PARÁGRAFO OU VERSÍCULO:
"$contextText"

FONTES OFICIAIS CONSULTADAS NO WOL.JW.ORG (Biblioteca On-line da Torre de Vigia):
${wolContextBuffer.toString()}

DIRETRIZES OBRIGATÓRIAS:
1. RESTRIÇÃO ABSOLUTA DE FONTES:
Baseie sua explicação EXCLUSIVAMENTE nas publicações oficiais das Testemunhas de Jeová.
É EXPRESSAMENTE PROIBIDO utilizar teologias ou dogmas de outras denominações religiosas (como Trindade, alma imortal, inferno de fogo, etc.) ou especulações seculares.

2. ESTRUTURA DA RESPOSTA:
- "explanation": Explicação clara, bíblica e direta (de 2 a 4 frases) do significado do termo ou versículo selecionado. Vá direto ao ponto.
- "application": Aplicação prática rápida para o dia a dia ou para comentar na reunião congregacional (1 a 2 frases).
- "officialSource": Nome da principal publicação oficial de onde a explicação deriva (ex: "Estudo Perspicaz das Escrituras", "A Sentinela", ou "Tradução do Novo Mundo - Nota de Estudo").

3. REGRA DE SAUDAÇÕES:
NUNCA use saudações, introduções ou vocativos (proibido usar "Olá!", "Irmãos", "Queridos irmãos", "Respondendo:", etc.). Comece a explicação imediatamente.

4. AUSÊNCIA DE FONTES:
Se o assunto não estiver fundamentado nas publicações oficiais da Torre de Vigia, retorne na explicação:
"Não foram encontradas considerações oficiais nas publicações para este termo específico."

Retorne EXCLUSIVAMENTE um objeto JSON no seguinte formato:
{
  "explanation": "...",
  "application": "...",
  "officialSource": "..."
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
        'temperature': 0.2,
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

    return _parseResponse(text.toString(), wolResults);
  }

  AiExplanationResult _parseResponse(String rawText, List<WolSearchResult> sources) {
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
      final rawExpl = (jsonResponse['explanation'] ?? '').toString().trim();
      final rawApp = (jsonResponse['application'] ?? '').toString().trim();
      final rawSrc = (jsonResponse['officialSource'] ?? '').toString().trim();

      return AiExplanationResult(
        explanation: _geminiService.sanitizeAnswer(rawExpl),
        application: rawApp.isNotEmpty ? _geminiService.sanitizeAnswer(rawApp) : null,
        officialSource: rawSrc.isNotEmpty ? rawSrc : 'Biblioteca On-line da Torre de Vigia (wol.jw.org)',
        sources: sources,
      );
    } catch (_) {
      final explMatch = RegExp(r'"explanation"\s*:\s*"([^"]+)"').firstMatch(clean);
      final appMatch = RegExp(r'"application"\s*:\s*"([^"]+)"').firstMatch(clean);
      final srcMatch = RegExp(r'"officialSource"\s*:\s*"([^"]+)"').firstMatch(clean);

      if (explMatch != null) {
        return AiExplanationResult(
          explanation: _geminiService.sanitizeAnswer(explMatch.group(1) ?? clean),
          application: appMatch != null ? _geminiService.sanitizeAnswer(appMatch.group(1)!) : null,
          officialSource: srcMatch?.group(1) ?? 'wol.jw.org',
          sources: sources,
        );
      }

      return AiExplanationResult(
        explanation: _geminiService.sanitizeAnswer(clean),
        sources: sources,
      );
    }
  }
}
