import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/issue.dart';
import 'seed_catalog.dart';

class JwApiService {
  static const List<String> _baseEndpoints = [
    'https://app.jw-cdn.org/apis/pub-media/GETPUBMEDIALINKS',
    'https://b.jw-cdn.org/apis/pub-media/GETPUBMEDIALINKS',
  ];

  static const List<String> _langCodes = ['TPO', 'T', 'PO'];
  static const List<String> _pubCodes = ['w', 'ws'];

  /// Lista de anos suportados para navegação (igual ao JW Library oficial)
  List<int> getAvailableYears() {
    return [2027, 2026, 2025, 2024, 2023, 2022, 2021, 2020, 2019];
  }

  /// Retorna as edições de um determinado ano de forma ultra-rápida (Catálogo Local Instantâneo)
  Future<List<WatchtowerIssue>> getIssuesForYear(int year) async {
    final appDir = await getApplicationDocumentsDirectory();
    final issuesDir = Directory(p.join(appDir.path, 'issues'));
    if (!await issuesDir.exists()) {
      await issuesDir.create(recursive: true);
    }

    final prefs = await SharedPreferences.getInstance();
    final seedIssues = SeedCatalog.getStudyIssuesForYear(year);
    final enrichedIssues = <WatchtowerIssue>[];

    for (final issue in seedIssues) {
      final code = issue.issueCode;
      final localEpub = p.join(issuesDir.path, 'w_$code.epub');
      final localJwpub = p.join(issuesDir.path, 'w_$code.jwpub');

      bool isDownloaded = false;
      String? localPath;

      if (await File(localEpub).exists()) {
        isDownloaded = true;
        localPath = localEpub;
      } else if (await File(localJwpub).exists()) {
        isDownloaded = true;
        localPath = localJwpub;
      }

      final cachedCover = prefs.getString('cover_$code');
      final cachedFile = prefs.getString('file_$code');

      enrichedIssues.add(WatchtowerIssue(
        issueCode: code,
        title: issue.title,
        studyPeriod: issue.studyPeriod,
        fileSize: issue.fileSize,
        coverUrl: cachedCover ?? issue.coverUrl,
        fileUrl: cachedFile ?? issue.fileUrl,
        isDownloaded: isDownloaded,
        localPath: localPath,
        isPublicEdition: false,
      ));
    }

    return enrichedIssues;
  }

  /// Sincronização ultra-rápida concorrente (Fast-Sync) com o CDN oficial
  Future<int> syncLatestReleases() async {
    final prefs = await SharedPreferences.getInstance();
    int newIssuesFound = 0;

    final now = DateTime.now();
    // Prioriza o ano atual e o próximo ano
    final yearsToSync = [now.year, now.year + 1];
    final tasks = <Future<void>>[];

    // Agrupa meses para requisições concorrentes controladas
    for (final year in yearsToSync) {
      for (int month = 1; month <= 12; month++) {
        final monthStr = month.toString().padLeft(2, '0');
        final issueCode = '$year$monthStr';

        // Se já tem link no cache persistente, pula
        if (prefs.containsKey('file_$issueCode')) continue;

        tasks.add(() async {
          try {
            final meta = await fetchIssueMetadata(issueCode);
            if (meta != null && meta.fileUrl != null) {
              await prefs.setString('file_$issueCode', meta.fileUrl!);
              if (meta.coverUrl != null) {
                await prefs.setString('cover_$issueCode', meta.coverUrl!);
              }
              newIssuesFound++;
            }
          } catch (_) {}
        }());

        // Limita a concorrência a 4 requisições simultâneas para não sobrecarregar
        if (tasks.length >= 4) {
          await Future.wait(tasks);
          tasks.clear();
        }
      }
    }

    if (tasks.isNotEmpty) {
      await Future.wait(tasks);
    }

    return newIssuesFound;
  }

  /// Resolve a URL de download oficial nos servidores CDN da JW
  Future<WatchtowerIssue?> fetchIssueMetadata(String issueCode) async {
    for (final baseUrl in _baseEndpoints) {
      for (final pubCode in _pubCodes) {
        for (final lang in _langCodes) {
          try {
            final uri = Uri.parse(
              '$baseUrl?output=json&pub=$pubCode&issue=$issueCode&fileformat=JWPUB,EPUB&langwritten=$lang&alllangs=0',
            );

            final response = await http
                .get(uri, headers: {'User-Agent': 'Mozilla/5.0'})
                .timeout(const Duration(seconds: 3));

            if (response.statusCode != 200) continue;

            final data = jsonDecode(response.body);
            final filesMap = data['files'];
            if (filesMap is! Map) continue;

            Map<String, dynamic>? langFiles;
            for (final lk in ['TPO', 'T', 'PO']) {
              if (filesMap[lk] is Map) {
                langFiles = Map<String, dynamic>.from(filesMap[lk]);
                break;
              }
            }
            if (langFiles == null && filesMap.isNotEmpty) {
              langFiles = Map<String, dynamic>.from(filesMap.values.first);
            }

            if (langFiles == null) continue;

            List? items;
            String foundFormat = 'EPUB';

            if (langFiles['JWPUB'] is List && (langFiles['JWPUB'] as List).isNotEmpty) {
              items = langFiles['JWPUB'] as List;
              foundFormat = 'JWPUB';
            } else if (langFiles['EPUB'] is List && (langFiles['EPUB'] as List).isNotEmpty) {
              items = langFiles['EPUB'] as List;
              foundFormat = 'EPUB';
            }

            if (items == null || items.isEmpty) continue;

            final item = items.first;
            final fileUrl = item['file']?['url'];
            final coverUrl = item['images']?['wss']?['lg'] ?? item['images']?['wss']?['sm'];
            final title = item['title'] ?? 'A Sentinela $issueCode';

            if (fileUrl != null && fileUrl.toString().isNotEmpty) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('file_$issueCode', fileUrl);
              if (coverUrl != null) {
                await prefs.setString('cover_$issueCode', coverUrl);
              }

              return WatchtowerIssue(
                issueCode: issueCode,
                title: title,
                coverUrl: coverUrl,
                fileUrl: fileUrl,
                format: foundFormat,
              );
            }
          } catch (_) {}
        }
      }
    }

    return null;
  }

  /// Faz o download da publicação para o armazenamento local com tracking de progresso
  Future<String> downloadIssue(
    WatchtowerIssue issue, {
    void Function(double progress)? onProgress,
  }) async {
    if (issue.fileUrl == null || issue.fileUrl!.isEmpty) {
      final meta = await fetchIssueMetadata(issue.issueCode);
      if (meta != null && meta.fileUrl != null) {
        issue.fileUrl = meta.fileUrl;
        issue.format = meta.format;
      } else {
        throw Exception('Esta edição ainda não foi liberada no CDN oficial da JW.');
      }
    }

    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'issues'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final ext = issue.format.toLowerCase() == 'jwpub' ? 'jwpub' : 'epub';
    final localFilePath = p.join(dir.path, 'w_${issue.issueCode}.$ext');
    final tempFilePath = '$localFilePath.tmp';
    final tempFile = File(tempFilePath);

    final client = http.Client();
    IOSink? sink;

    try {
      final request = http.Request('GET', Uri.parse(issue.fileUrl!));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Erro ao baixar arquivo (código HTTP ${response.statusCode})');
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (await File(localFilePath).exists()) {
        await File(localFilePath).delete();
      }
      await tempFile.rename(localFilePath);

      issue.isDownloaded = true;
      issue.localPath = localFilePath;
      return localFilePath;
    } catch (e) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    } finally {
      await sink?.close();
      client.close();
    }
  }

  /// Exclui o arquivo baixado localmente
  Future<void> deleteDownloadedIssue(WatchtowerIssue issue) async {
    if (issue.localPath != null) {
      final file = File(issue.localPath!);
      if (await file.exists()) {
        await file.delete();
      }
      issue.isDownloaded = false;
      issue.localPath = null;
    }
  }
}
