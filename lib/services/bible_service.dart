import 'package:http/http.dart' as http;
import 'bible_content_catalog.dart';
import 'dart:async';
import 'pub_media_client.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import '../models/bible_model.dart';

class BibleService {
  static const String _prefActiveVersionKey = 'bible_active_version_id';
  static final Map<String, Future<void>> _activeDownloadTasks = {};

  static Archive _decodeZip(List<int> bytes) => ZipDecoder().decodeBytes(bytes);

  bool isDownloading(String versionId) => _activeDownloadTasks.containsKey(versionId);
  static const String _defaultVersionId = 'nwt_t';

    static const List<BibleBook> books = BibleContentCatalog.books;


  static const List<BibleVersion> defaultVersions = BibleContentCatalog.defaultVersions;

  Future<String> getActiveVersionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefActiveVersionKey) ?? _defaultVersionId;
  }

  Future<void> setActiveVersionId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefActiveVersionKey, id);
  }

  Future<BibleVersion> getActiveVersion() async {
    final id = await getActiveVersionId();
    final versions = await getVersions();
    return versions.firstWhere((v) => v.id == id, orElse: () => versions.first);
  }

  Future<List<BibleVersion>> getVersions() async {
    final baseDir = await _getBiblesDirectory();
    final list = <BibleVersion>[];

    for (final v in defaultVersions) {
      final vDir = Directory(p.join(baseDir.path, v.id));
      final exists = await _hasValidBibleContent(vDir);
      list.add(v.copyWith(isDownloaded: exists));
    }

    return list;
  }

  Future<Directory> _getBiblesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final biblesDir = Directory(p.join(appDir.path, 'bibles'));
    if (!await biblesDir.exists()) {
      await biblesDir.create(recursive: true);
    }
    return biblesDir;
  }

  Future<bool> _hasValidBibleContent(Directory dir) async {
    if (!await dir.exists()) return false;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final name = p.basename(entity.path).toLowerCase();
          if (name.endsWith('.xhtml') || name.endsWith('.html')) {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  Future<bool> isVersionDownloaded(String versionId) async {
    final baseDir = await _getBiblesDirectory();
    final vDir = Directory(p.join(baseDir.path, versionId));
    return _hasValidBibleContent(vDir);
  }

  /// Resolve a URL final da CDN para download usando o PubMediaClient
  Future<String> resolveDownloadUrl(BibleVersion version) async {
    final client = PubMediaClient();
    try {
      final pub = await client.getPublication(
        pubCode: version.pubCode,
        language: version.langCode,
        fileFormat: 'JWPUB,EPUB',
      );
      final preferred = pub?.preferredFile(
        preferredLanguage: version.langCode,
        preferredFormats: const ['JWPUB', 'EPUB'],
      );
      if (preferred != null && preferred.url.isNotEmpty) {
        return preferred.url;
      }
    } catch (_) {
    } finally {
      client.close();
    }

    return version.directUrl;
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDirectory = Directory(p.join(destination.path, p.basename(entity.path)));
        await newDirectory.create(recursive: true);
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        await entity.copy(p.join(destination.path, p.basename(entity.path)));
      }
    }
  }

  /// Extrai de forma segura prevenindo vulnerabilidade de Zip Slip / Path Traversal
  Future<void> _safeExtractArchive(Archive archive, Directory targetDir) async {
    final normalizedTarget = p.normalize(targetDir.path);
    for (final file in archive) {
      if (!file.isFile) continue;
      final resolvedPath = p.normalize(p.join(targetDir.path, file.name));
      if (!p.isWithin(normalizedTarget, resolvedPath) && resolvedPath != normalizedTarget) {
        throw FormatException('Caminho de arquivo inseguro detectado no arquivo ZIP: ${file.name}');
      }
      final outFile = File(resolvedPath);
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
    }
  }

  /// Realiza o download seguro e extração da Bíblia diretamente da CDN oficial
  Future<void> downloadVersion(
    BibleVersion version, {
    void Function(double progress)? onProgress,
  }) async {
    final existing = _activeDownloadTasks[version.id];
    if (existing != null) {
      return existing;
    }

    final completer = Completer<void>();
    _activeDownloadTasks[version.id] = completer.future;

    try {
      await _performDownloadVersion(version, onProgress: onProgress);
      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _activeDownloadTasks.remove(version.id);
    }
  }

  Future<void> _performDownloadVersion(
    BibleVersion version, {
    void Function(double progress)? onProgress,
  }) async {

    final baseDir = await _getBiblesDirectory();
    final targetDir = Directory(p.join(baseDir.path, version.id));
    final tempZipFile = File(p.join(baseDir.path, '${version.id}_temp.zip'));
    final client = PubMediaClient();

    try {
      final pub = await client.getPublication(
        pubCode: version.pubCode,
        language: version.langCode,
        fileFormat: 'JWPUB,EPUB',
      );

      final isStudyBible = version.id == 'nwtsty_t';
      final preferredFormats = isStudyBible
          ? const ['JWPUB', 'EPUB']
          : const ['EPUB', 'JWPUB'];
      final preferredFile = pub?.preferredFile(
        preferredLanguage: version.langCode,
        preferredFormats: preferredFormats,
      );

      if (preferredFile != null) {
        await client.downloadFile(
          file: preferredFile,
          destinationFile: tempZipFile,
          onProgress: onProgress,
          verifyChecksum: preferredFile.checksum.isNotEmpty,
        );
      } else {
        final downloadUrl = await resolveDownloadUrl(version);
        final fallbackFile = PubMediaFile(
          url: downloadUrl,
          filename: '${version.id}_temp.zip',
          title: version.title,
          language: version.langCode,
          fileFormat: downloadUrl.endsWith('.jwpub') ? 'JWPUB' : 'EPUB',
          sizeBytes: version.sizeBytes,
        );
        await client.downloadFile(
          file: fallbackFile,
          destinationFile: tempZipFile,
          onProgress: onProgress,
          verifyChecksum: false,
        );
      }

      // Extrai o pacote em background isolate para não travar a UI
      final bytes = await tempZipFile.readAsBytes();
      final archive = await compute(_decodeZip, bytes);

      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
      }
      await targetDir.create(recursive: true);

      // Se for JWPUB (que contém um ZIP interno 'contents')
      final contentsEntry = archive.findFile('contents');
      if (contentsEntry != null) {
        final innerArchive = await compute(_decodeZip, contentsEntry.content as List<int>);
        await _safeExtractArchive(innerArchive, targetDir);
      } else {
        // Pacote EPUB padrão
        await _safeExtractArchive(archive, targetDir);
      }

      // Se for Bíblia de Estudo (nwtsty_t), extrai também o texto bíblico oficial (nwt)
      if (version.id == 'nwtsty_t') {
        try {
          final nwtTDir = Directory(p.join(baseDir.path, 'nwt_t'));
          if (await nwtTDir.exists() && await _hasValidBibleContent(nwtTDir)) {
            await _copyDirectory(nwtTDir, targetDir);
          } else {
            final nwtPub = await client.getPublication(
              pubCode: 'nwt',
              language: version.langCode,
              fileFormat: 'EPUB,JWPUB',
            );
            final nwtFile = nwtPub?.preferredFile(
              preferredLanguage: version.langCode,
              preferredFormats: const ['EPUB', 'JWPUB'],
            );
            if (nwtFile != null) {
              final nwtTemp = File(p.join(baseDir.path, 'nwt_temp_${version.langCode}.zip'));
              try {
                await client.downloadFile(
                  file: nwtFile,
                  destinationFile: nwtTemp,
                  verifyChecksum: nwtFile.checksum.isNotEmpty,
                );
                final nwtBytes = await nwtTemp.readAsBytes();
                final nwtArchive = await compute(_decodeZip, nwtBytes);
                final inner = nwtArchive.findFile('contents');
                if (inner != null) {
                  final innerArchive = await compute(_decodeZip, inner.content as List<int>);
                  await _safeExtractArchive(innerArchive, targetDir);
                } else {
                  await _safeExtractArchive(nwtArchive, targetDir);
                }
              } finally {
                if (await nwtTemp.exists()) await nwtTemp.delete();
              }
            }
          }
        } catch (e) {
          debugPrint('Aviso: falha ao sincronizar texto complementar para nwtsty_t: $e');
        }
      }
    } finally {
      client.close();
      if (await tempZipFile.exists()) {
        try {
          await tempZipFile.delete();
        } catch (_) {}
      }
    }
  }

  /// Remove uma versão baixada com validação contra Path Traversal
  Future<void> deleteVersion(String versionId) async {
    final baseDir = await _getBiblesDirectory();
    final targetDir = Directory(p.join(baseDir.path, versionId));
    final normalizedBase = p.normalize(baseDir.path);
    final normalizedTarget = p.normalize(targetDir.path);
    if (p.isWithin(normalizedBase, normalizedTarget) && await targetDir.exists()) {
      await targetDir.delete(recursive: true);
    }
  }

  /// Carrega o conteúdo de um capítulo bíblico
  Future<BibleChapterContent> loadChapter(BibleBook book, int chapter) async {
    final version = await getActiveVersion();
    final baseDir = await _getBiblesDirectory();
    final targetDir = Directory(p.join(baseDir.path, version.id));

    // Fallback de diretório para Bíblia de Estudo se nwt_t já estiver baixada
    Directory activeDir = targetDir;
    if (!await activeDir.exists() && version.id == 'nwtsty_t') {
      final nwtDir = Directory(p.join(baseDir.path, 'nwt_t'));
      if (await nwtDir.exists()) {
        activeDir = nwtDir;
      }
    }

    if (!await activeDir.exists()) {
      return await _generateOnlineOrPlaceholderChapter(book, chapter);
    }

    // 1. Tenta carregar do EPUB padrão (OEBPS/docId.xhtml)
    final epubChapter = await _tryLoadFromEpub(activeDir, book, chapter);
    if (epubChapter != null) {
      return epubChapter;
    }

    // 2. Se for a Bíblia de 1986 (bi12_t), tenta carregar pelo formato BI12
    if (version.id == 'bi12_t') {
      final bi12Chapter = await _tryLoadFromBi12(activeDir, book, chapter);
      if (bi12Chapter != null) {
        return bi12Chapter;
      }
    }

    // 3. Se for Bíblia de Estudo e não encontrou no diretório dela, busca em nwt_t
    if (version.id == 'nwtsty_t') {
      final nwtDir = Directory(p.join(baseDir.path, 'nwt_t'));
      if (await nwtDir.exists()) {
        final fallbackChapter = await _tryLoadFromEpub(nwtDir, book, chapter);
        if (fallbackChapter != null) {
          return fallbackChapter;
        }
      }
      _ensureStudyBibleText(version, activeDir);
    }

    return await _generateOnlineOrPlaceholderChapter(book, chapter);
  }

  Future<BibleChapterContent?> _tryLoadFromEpub(
    Directory targetDir,
    BibleBook book,
    int chapter,
  ) async {
    // Arquivo inicial para Gênesis é 1001061105.xhtml, Êxodo é 1001061106.xhtml, etc.
    // DocId base para livros bíblicos no nwt_TPO: 1001061104 + book.id
    final docId = 1001061104 + book.id;
    final fileName = (chapter == 1)
        ? '$docId.xhtml'
        : '$docId-split$chapter.xhtml';

    final possiblePaths = [
      p.join(targetDir.path, 'OEBPS', fileName),
      p.join(targetDir.path, fileName),
    ];

    File? foundFile;
    for (final path in possiblePaths) {
      final f = File(path);
      if (await f.exists()) {
        foundFile = f;
        break;
      }
    }

    if (foundFile == null) {
      try {
        await for (final entity in targetDir.list(recursive: true)) {
          if (entity is File && p.basename(entity.path).toLowerCase() == fileName.toLowerCase()) {
            foundFile = entity;
            break;
          }
        }
      } catch (_) {}
    }
    if (foundFile == null) {
      return null;
    }

    final xhtml = await foundFile.readAsString();
    return _parseXhtmlChapter(book, chapter, xhtml);
  }

  static const Map<int, String> _bi12BookAbbr = BibleContentCatalog.bi12BookAbbr;

  Future<BibleChapterContent?> _tryLoadFromBi12(
    Directory targetDir,
    BibleBook book,
    int chapter,
  ) async {
    final abbr = _bi12BookAbbr[book.id];
    if (abbr == null) return null;

    final targetSuffix = (chapter == 1) ? '.$abbr.xhtml' : '.$abbr-split$chapter.xhtml';

    final searchDirs = [
      Directory(p.join(targetDir.path, 'OEBPS')),
      targetDir,
    ];

    for (final dir in searchDirs) {
      if (!await dir.exists()) continue;
      await for (final file in dir.list()) {
        if (file is File && file.path.endsWith(targetSuffix)) {
          final xhtml = await file.readAsString();
          return _parseXhtmlChapter(book, chapter, xhtml);
        }
      }
    }

    return null;
  }

  @visibleForTesting
  BibleChapterContent parseXhtmlChapter(
    BibleBook book,
    int chapter,
    String xhtml,
  ) => _parseXhtmlChapter(book, chapter, xhtml);

  static String _cleanVerseSlice(String slice) => slice
      .replaceAll(RegExp(r'<span[^>]*class="pageNum"[^>]*>.*?</span>', caseSensitive: false, dotAll: true), '')
      .replaceAll(RegExp(r'<a\b[^>]*>.*?</a>', caseSensitive: false, dotAll: true), '')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('*', '')
      .replaceAll('+', '')
      .trim();

  static List<BibleVerseToken> _parseVerseTokens(
    String rawHtml,
    Map<String, String> footnotes,
  ) {
    final tokens = <BibleVerseToken>[];
    final anchorRegex = RegExp(
      r'<a\b([^>]*)>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    );
    int lastIndex = 0;

    for (final match in anchorRegex.allMatches(rawHtml)) {
      if (match.start > lastIndex) {
        final textSlice = rawHtml.substring(lastIndex, match.start);
        final cleanText = _cleanVerseSlice(textSlice);
        if (cleanText.isNotEmpty) {
          tokens.add(BibleVerseToken.text(cleanText));
        }
      }

      final rawAttrs = match.group(1) ?? '';
      final attrs = rawAttrs.toLowerCase();
      final innerText = (match.group(2) ?? '').replaceAll(RegExp(r'<[^>]+>'), '').trim();
      final hrefMatch = RegExp(r'href="([^"]*)"', caseSensitive: false).firstMatch(rawAttrs);
      final href = hrefMatch?.group(1) ?? '';

      final isFootnote = attrs.contains('w_fn') ||
          attrs.contains('noteref') ||
          attrs.contains('footnote') ||
          attrs.contains(RegExp(r'\bfn\b')) ||
          innerText == '*';

      final isCrossRef = attrs.contains('w_cr') ||
          attrs.contains(RegExp(r'\bb\b')) ||
          attrs.contains('/bc/') ||
          innerText == '+';

      if (isFootnote) {
        final fnMatch = RegExp(r'(?:data-fnid="(\d+)"|id="footnotesource(\d+)"|href="[^"]*?(?:footnote|fn)?(\d+)")', caseSensitive: false).firstMatch(rawAttrs);
        final numId = fnMatch?.group(1) ?? fnMatch?.group(2) ?? fnMatch?.group(3);
        final cleanHref = href.replaceAll('#', '').trim();
        final fnId = (cleanHref.isNotEmpty && !cleanHref.contains('/')) ? cleanHref : (numId ?? cleanHref);
        final fnText = footnotes[fnId] ??
            footnotes[numId] ??
            footnotes['footnote$numId'] ??
            footnotes['fn$numId'] ??
            footnotes['verseFootnote-$numId'] ??
            footnotes[cleanHref] ??
            'Nota explicativa';
        tokens.add(BibleVerseToken.footnote(
          footnoteId: fnId,
          footnoteText: fnText,
        ));
      } else if (isCrossRef) {
        final crText = innerText.isNotEmpty ? innerText : '+';
        tokens.add(BibleVerseToken.crossRef(
          crossRefTarget: href,
          text: crText,
        ));
      }
      lastIndex = match.end;
    }

    if (lastIndex < rawHtml.length) {
      final textSlice = rawHtml.substring(lastIndex);
      final cleanText = _cleanVerseSlice(textSlice);
      if (cleanText.isNotEmpty) {
        tokens.add(BibleVerseToken.text(cleanText));
      }
    }

    return tokens;
  }

  BibleChapterContent _parseXhtmlChapter(
    BibleBook book,
    int chapter,
    String xhtml,
  ) {
    final verses = <BibleVerseItem>[];
    final footnotes = <String, String>{};

    // Extrai notas de rodapé de todas as variações (li, div, aside, p) em EPUB e WOL
    final footnoteMatches = RegExp(
      r'<(?:li|div|p|aside)[^>]*(?:id="((?:verseFootnote-|footnote|fn)?\d+)"|data-extract-id="((?:verseFootnote-|footnote|fn)?\d+)")[^>]*>(.*?)</(?:li|div|p|aside)>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(xhtml);

    for (final m in footnoteMatches) {
      final rawId = m.group(1) ?? m.group(2) ?? '';
      final numMatch = RegExp(r'\d+').firstMatch(rawId);
      final rawContent = m.group(3) ?? '';
      final content = rawContent
          .replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceFirst(RegExp(r'^\*\s*'), '')
          .trim();
      if (content.isNotEmpty) {
        if (numMatch != null) {
          final digits = numMatch.group(0)!;
          footnotes[digits] = content;
          footnotes['footnote$digits'] = content;
          footnotes['fn$digits'] = content;
          footnotes['verseFootnote-$digits'] = content;
        }
        if (rawId.isNotEmpty) {
          footnotes[rawId] = content;
        }
      }
    }

    // Estratégia 1: Formato WOL com marcações por versículo <span id="v...-\d+-\d+" class="v">
    final spanVMatches = RegExp(
      r'<span id="v\d+-\d+-(\d+)-\d+" class="v">([\s\S]*?)</span>',
      caseSensitive: false,
    ).allMatches(xhtml).toList();

    if (spanVMatches.isNotEmpty) {
      for (final vm in spanVMatches) {
        final vNum = int.tryParse(vm.group(1) ?? '') ?? (verses.length + 1);
        final rawVerseHtml = vm.group(2) ?? '';
        final cleanText = _cleanVerseSlice(rawVerseHtml);

        final vTokens = _parseVerseTokens(rawVerseHtml, footnotes);
        final vFootnotes = vTokens
            .where((t) => t.isFootnote && t.footnoteText != null)
            .map((t) => t.footnoteText!)
            .toList();
        final vCrossRefs = vTokens
            .where((t) => t.isCrossRef && t.crossRefTarget != null)
            .map((t) => t.crossRefTarget!)
            .toList();

        if (cleanText.isNotEmpty || vTokens.isNotEmpty) {
          verses.add(BibleVerseItem(
            verseNumber: vNum,
            text: cleanText,
            footnotes: vFootnotes,
            crossRefs: vCrossRefs,
            tokens: vTokens,
          ));
        }
      }

      if (verses.isNotEmpty) {
        return BibleChapterContent(
          bookNumber: book.id,
          bookName: book.name,
          chapterNumber: chapter,
          verses: verses,
          footnotes: footnotes,
        );
      }
    }

    // Estratégia 2: Formato EPUB padrão (parágrafos sb, sl, sz, sp com w_ch ou sup)
    final pMatches = RegExp(
      r'<p[^>]*class="[^"]*(?:sb|sl|sz|sp)[^"]*"[^>]*>(.*?)</p>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(xhtml);

    for (final pMatch in pMatches) {
      final pContent = pMatch.group(1) ?? '';
      final parts = pContent.split(RegExp(
        r'(?:<span[^>]*class="w_ch"[^>]*><strong>\d+</strong>\s*</span>|(?:<strong><sup>\d+</sup></strong>|<sup><strong>\d+</strong></sup>|<sup>\d+</sup>))',
        caseSensitive: false,
      ));
      final numMatches = RegExp(
        r'(?:class="w_ch"[^>]*><strong>(\d+)</strong>|(?:<strong><sup>(\d+)</sup></strong>|<sup><strong>(\d+)</strong></sup>|<sup>(\d+)</sup>))',
        caseSensitive: false,
      ).allMatches(pContent).toList();

      if (numMatches.isEmpty && verses.isNotEmpty) {
        final contTokens = _parseVerseTokens(pContent, footnotes);
        var contText = _cleanVerseSlice(pContent);
        if (contText.isNotEmpty || contTokens.isNotEmpty) {
          final lastVerse = verses.removeLast();
          final updatedTokens = List<BibleVerseToken>.from(lastVerse.tokens);
          if (contTokens.isNotEmpty) {
            final first = contTokens.first;
            if (!first.isFootnote && !first.isCrossRef) {
              contTokens[0] = BibleVerseToken.text(' ${first.text}');
            } else {
              updatedTokens.add(const BibleVerseToken.text(' '));
            }
            updatedTokens.addAll(contTokens);
          }
          final updatedFootnotes = List<String>.from(lastVerse.footnotes)
            ..addAll(contTokens.where((t) => t.isFootnote && t.footnoteText != null).map((t) => t.footnoteText!));
          final updatedCrossRefs = List<String>.from(lastVerse.crossRefs)
            ..addAll(contTokens.where((t) => t.isCrossRef && t.crossRefTarget != null).map((t) => t.crossRefTarget!));

          verses.add(BibleVerseItem(
            verseNumber: lastVerse.verseNumber,
            text: contText.isNotEmpty ? '${lastVerse.text} $contText' : lastVerse.text,
            footnotes: updatedFootnotes,
            crossRefs: updatedCrossRefs,
            tokens: updatedTokens,
          ));
        }
        continue;
      }

      for (int i = 0; i < numMatches.length; i++) {
        final m = numMatches[i];
        final int vNum = m.group(1) != null
            ? 1
            : (int.tryParse(m.group(2) ?? m.group(3) ?? m.group(4) ?? '') ?? (i + 1));
        final rawText = (i + 1 < parts.length) ? parts[i + 1] : '';

        var cleanText = _cleanVerseSlice(rawText);

        final vTokens = _parseVerseTokens(rawText, footnotes);
        final vFootnotes = vTokens
            .where((t) => t.isFootnote && t.footnoteText != null)
            .map((t) => t.footnoteText!)
            .toList();
        final vCrossRefs = vTokens
            .where((t) => t.isCrossRef && t.crossRefTarget != null)
            .map((t) => t.crossRefTarget!)
            .toList();

        if (cleanText.isNotEmpty || vTokens.isNotEmpty) {
          verses.add(BibleVerseItem(
            verseNumber: vNum,
            text: cleanText,
            footnotes: vFootnotes,
            crossRefs: vCrossRefs,
            tokens: vTokens,
          ));
        }
      }
    }

    return BibleChapterContent(
      bookNumber: book.id,
      bookName: book.name,
      chapterNumber: chapter,
      verses: verses,
      footnotes: footnotes,
    );
  }

  Future<BibleChapterContent> _generateOnlineOrPlaceholderChapter(
    BibleBook book,
    int chapter,
  ) async {
    // 1. Tenta buscar online via wol.jw.org (nwtsty ou nwt) e salvar cache local
    final candidateUrls = [
      Uri.parse('https://wol.jw.org/pt/wol/b/r5/lp-t/nwtsty/${book.id}/$chapter'),
      Uri.parse('https://wol.jw.org/pt/wol/b/r5/lp-t/nwt/${book.id}/$chapter'),
    ];

    for (final url in candidateUrls) {
      try {
        final response = await http.get(url).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200 &&
            (response.body.contains('class="sb"') || response.body.contains('class="v"'))) {
          final parsed = _parseXhtmlChapter(book, chapter, response.body);
          if (parsed.verses.isNotEmpty) {
            _cacheChapterLocally(book, chapter, response.body);
            return parsed;
          }
        }
      } catch (_) {}
    }

    // 2. Versículos essenciais pré-carregados para Gênesis 1 caso offline sem download prévio
    if (book.id == 1 && chapter == 1) {
      return const BibleChapterContent(
        bookNumber: 1,
        bookName: 'Gênesis',
        chapterNumber: 1,
        verses: BibleContentCatalog.genesis1FallbackVerses,
      );
    }

    // 3. Fallback informativo
    return BibleChapterContent(
      bookNumber: book.id,
      bookName: book.name,
      chapterNumber: chapter,
      verses: [
        BibleVerseItem(
          verseNumber: 1,
          text: 'Para ler todos os versículos de ${book.name} $chapter com texto completo e referências, faça o download da versão completa no menu de Idiomas.',
        ),
      ],
    );
  }

  void _cacheChapterLocally(BibleBook book, int chapter, String xhtml) async {
    try {
      final baseDir = await _getBiblesDirectory();
      final targetDir = Directory(p.join(baseDir.path, 'nwt_t', 'OEBPS'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final docId = 1001061104 + book.id;
      final fileName = (chapter == 1) ? '$docId.xhtml' : '$docId-split$chapter.xhtml';
      final file = File(p.join(targetDir.path, fileName));
      await file.writeAsString(xhtml);
    } catch (_) {}
  }

  void _ensureStudyBibleText(BibleVersion version, Directory targetDir) {
    if (_activeDownloadTasks.containsKey('sync_text_${version.id}')) return;
    final completer = Completer<void>();
    _activeDownloadTasks['sync_text_${version.id}'] = completer.future;
    completer.future.ignore();
    () async {
      final client = PubMediaClient();
      try {
        final baseDir = await _getBiblesDirectory();
        final nwtPub = await client.getPublication(
          pubCode: 'nwt',
          language: version.langCode,
          fileFormat: 'EPUB,JWPUB',
        );
        final nwtFile = nwtPub?.preferredFile(
          preferredLanguage: version.langCode,
          preferredFormats: const ['EPUB', 'JWPUB'],
        );
        if (nwtFile != null) {
          final tempFile = File(p.join(baseDir.path, 'nwt_recovery_${version.langCode}.zip'));
          try {
            await client.downloadFile(
              file: nwtFile,
              destinationFile: tempFile,
              verifyChecksum: nwtFile.checksum.isNotEmpty,
            );
            final bytes = await tempFile.readAsBytes();
            final archive = await compute(_decodeZip, bytes);
            final inner = archive.findFile('contents');
            if (inner != null) {
              final innerArchive = await compute(_decodeZip, inner.content as List<int>);
              await _safeExtractArchive(innerArchive, targetDir);
            } else {
              await _safeExtractArchive(archive, targetDir);
            }
          } finally {
            if (await tempFile.exists()) {
              try { await tempFile.delete(); } catch (_) {}
            }
          }
        }
        completer.complete();
      } catch (e) {
        debugPrint('Aviso: falha na sincronizacao em segundo plano: $e');
        if (!completer.isCompleted) completer.complete();
      } finally {
        client.close();
        _activeDownloadTasks.remove('sync_text_${version.id}');
      }
    }();
  }

}