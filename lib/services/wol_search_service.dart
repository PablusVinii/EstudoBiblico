import 'package:http/http.dart' as http;

/// Representa um resultado oficial de pesquisa na Biblioteca On-line da Torre de Vigia (wol.jw.org)
class WolSearchResult {
  final String title;
  final String publication;
  final String url;
  final String snippet;

  const WolSearchResult({
    required this.title,
    required this.publication,
    required this.url,
    required this.snippet,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'publication': publication,
      'url': url,
      'snippet': snippet,
    };
  }
}

/// Serviço cliente para pesquisar e extrair trechos oficiais do wol.jw.org em Português do Brasil (r5/lp-t)
class WolSearchService {
  static const String _baseUrl = 'https://wol.jw.org';
  static const String _searchPath = '/pt/wol/s/r5/lp-t';

  /// Realiza pesquisa em tempo real no wol.jw.org para obter fundamentação oficial
  static Future<List<WolSearchResult>> search({
    required String query,
    int maxResults = 3,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final searchUri = Uri.parse('$_baseUrl$_searchPath?q=${Uri.encodeQueryComponent(cleanQuery)}');
      final response = await http.get(
        searchUri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)',
          'Accept': 'text/html,application/xhtml+xml',
          'Accept-Language': 'pt-BR,pt;q=0.9',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return [];
      }

      final html = response.body;
      return _parseSearchResults(html, maxResults);
    } catch (_) {
      // Falha de rede ou timeout: retorna vazio para fallback seguro
      return [];
    }
  }

  /// Extrai os links, títulos e contexto dos documentos encontrados no HTML do WOL
  static List<WolSearchResult> _parseSearchResults(String html, int maxResults) {
    final results = <WolSearchResult>[];
    
    // Expressão regular para links de documentos /pt/wol/d/r5/lp-t/...
    final linkRegex = RegExp(r'<a[^>]+href="(/pt/wol/d/r5/lp-t/[^"]+)"[^>]*>(.*?)</a>');
    final matches = linkRegex.allMatches(html);

    final seenUrls = <String>{};

    for (final match in matches) {
      if (results.length >= maxResults) break;

      final path = match.group(1) ?? '';
      final rawTitle = match.group(2) ?? '';
      final fullUrl = '$_baseUrl$path';

      if (seenUrls.contains(fullUrl)) continue;
      seenUrls.add(fullUrl);

      final cleanTitle = _stripHtml(rawTitle).trim();
      if (cleanTitle.isEmpty) continue;

      // Dedução da publicação a partir do contexto ou título
      String publication = 'Biblioteca On-line da Torre de Vigia';
      if (cleanTitle.toLowerCase().contains('princípios') || cleanTitle.startsWith('A1') || cleanTitle.startsWith('C4')) {
        publication = 'Tradução do Novo Mundo (Bíblia de Estudo)';
      } else if (path.contains('120000') || path.contains('120027')) {
        publication = 'Estudo Perspicaz das Escrituras';
      } else if (cleanTitle.contains('CÂNTICO') || cleanTitle.contains('Sentinela') || path.contains('2026') || path.contains('2025')) {
        publication = 'Revista A Sentinela';
      }

      results.add(WolSearchResult(
        title: cleanTitle,
        publication: publication,
        url: fullUrl,
        snippet: 'Consulte a análise completa e considerações bíblicas no artigo oficial de .',
      ));
    }

    return results;
  }

  static String _stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
