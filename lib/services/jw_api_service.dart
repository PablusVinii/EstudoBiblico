import 'pub_media_client.dart';
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

      final epubFile = File(localEpub);
      final jwpubFile = File(localJwpub);
      final epubExists = await epubFile.exists() && (await epubFile.length()) > 1000;
      final jwpubExists = await jwpubFile.exists() && (await jwpubFile.length()) > 1000;

      bool isDownloaded = false;
      String? localPath;

      if (jwpubExists) {
        isDownloaded = true;
        localPath = localJwpub;
      } else if (epubExists) {
        isDownloaded = true;
        localPath = localEpub;
      }

      final cachedCover = prefs.getString('cover_$code');
      final cachedFile = prefs.getString('file_$code');
      final cachedChecksum = prefs.getString('checksum_$code');
      final cachedFormat = prefs.getString('format_$code');

      final effectiveFormat = cachedFormat ??
          (jwpubExists || cachedFile?.toLowerCase().endsWith('.jwpub') == true ? 'JWPUB' : 'EPUB');

      enrichedIssues.add(WatchtowerIssue(
        issueCode: code,
        title: issue.title,
        studyPeriod: issue.studyPeriod,
        fileSize: issue.fileSize,
        coverUrl: cachedCover ?? issue.coverUrl,
        fileUrl: cachedFile ?? issue.fileUrl,
        format: effectiveFormat,
        checksum: cachedChecksum ?? issue.checksum,
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
            final checksum = item['file']?['checksum']?.toString();

            if (fileUrl != null && fileUrl.toString().isNotEmpty) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('file_$issueCode', fileUrl);
              await prefs.setString('format_$issueCode', foundFormat);
              if (coverUrl != null) {
                await prefs.setString('cover_$issueCode', coverUrl);
              }
              if (checksum != null && checksum.isNotEmpty) {
                await prefs.setString('checksum_$issueCode', checksum);
              }

              return WatchtowerIssue(
                issueCode: issueCode,
                title: title,
                coverUrl: coverUrl,
                fileUrl: fileUrl,
                format: foundFormat,
                checksum: checksum,
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

    final isJwpub = issue.format.toUpperCase() == 'JWPUB' ||
        (issue.fileUrl != null && issue.fileUrl!.toLowerCase().endsWith('.jwpub'));
    final ext = isJwpub ? 'jwpub' : 'epub';
    issue.format = isJwpub ? 'JWPUB' : 'EPUB';
    final localFilePath = p.join(dir.path, 'w_${issue.issueCode}.$ext');

    final pubClient = PubMediaClient();
    try {
      final mediaFile = PubMediaFile(
        url: issue.fileUrl!,
        filename: 'w_${issue.issueCode}.$ext',
        title: issue.title,
        language: 'T',
        fileFormat: issue.format,
        checksum: issue.checksum ?? '',
      );

      await pubClient.downloadFile(
        file: mediaFile,
        destinationFile: File(localFilePath),
        onProgress: onProgress,
        verifyChecksum: issue.checksum != null && issue.checksum!.isNotEmpty,
      );

      final oppositeExt = isJwpub ? 'epub' : 'jwpub';
      final oppositeFile = File(p.join(dir.path, 'w_${issue.issueCode}.$oppositeExt'));
      if (await oppositeFile.exists()) {
        try { await oppositeFile.delete(); } catch (_) {}
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('format_${issue.issueCode}', issue.format);
      issue.isDownloaded = true;
      issue.localPath = localFilePath;
      return localFilePath;
    } finally {
      pubClient.close();
    }
  }

  /// Exclui o arquivo baixado localmente
  Future<void> deleteDownloadedIssue(WatchtowerIssue issue) async {
    final appDir = await getApplicationDocumentsDirectory();
    final issuesDir = Directory(p.join(appDir.path, 'issues'));
    final epubFile = File(p.join(issuesDir.path, 'w_${issue.issueCode}.epub'));
    final jwpubFile = File(p.join(issuesDir.path, 'w_${issue.issueCode}.jwpub'));
    if (await epubFile.exists()) {
      try { await epubFile.delete(); } catch (_) {}
    }
    if (await jwpubFile.exists()) {
      try { await jwpubFile.delete(); } catch (_) {}
    }
    final extJwpub = Directory(p.join(issuesDir.path, 'extracted_jwpub', issue.issueCode));
    if (await extJwpub.exists()) {
      try { await extJwpub.delete(recursive: true); } catch (_) {}
    }
    final extImg = Directory(p.join(issuesDir.path, 'extracted_images', issue.issueCode));
    if (await extImg.exists()) {
      try { await extImg.delete(recursive: true); } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('format_${issue.issueCode}');
    issue.isDownloaded = false;
    issue.localPath = null;
  }
}
