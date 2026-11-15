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

  static const List<BibleBook> books = [
    // 1-5 Pentateuco / Lei
    BibleBook(id: 1, name: 'Gênesis', abbreviation: 'Gên', totalChapters: 50, isHebrew: true, category: 'pentateuch'),
    BibleBook(id: 2, name: 'Êxodo', abbreviation: 'Êx', totalChapters: 40, isHebrew: true, category: 'pentateuch'),
    BibleBook(id: 3, name: 'Levítico', abbreviation: 'Le', totalChapters: 27, isHebrew: true, category: 'pentateuch'),
    BibleBook(id: 4, name: 'Números', abbreviation: 'Núm', totalChapters: 36, isHebrew: true, category: 'pentateuch'),
    BibleBook(id: 5, name: 'Deuteronômio', abbreviation: 'De', totalChapters: 34, isHebrew: true, category: 'pentateuch'),

    // 6-17 Livros Históricos
    BibleBook(id: 6, name: 'Josué', abbreviation: 'Jos', totalChapters: 24, isHebrew: true, category: 'history'),
    BibleBook(id: 7, name: 'Juízes', abbreviation: 'Jz', totalChapters: 21, isHebrew: true, category: 'history'),
    BibleBook(id: 8, name: 'Rute', abbreviation: 'Ru', totalChapters: 4, isHebrew: true, category: 'history'),
    BibleBook(id: 9, name: '1 Samuel', abbreviation: '1Sa', totalChapters: 31, isHebrew: true, category: 'history'),
    BibleBook(id: 10, name: '2 Samuel', abbreviation: '2Sa', totalChapters: 24, isHebrew: true, category: 'history'),
    BibleBook(id: 11, name: '1 Reis', abbreviation: '1Rs', totalChapters: 22, isHebrew: true, category: 'history'),
    BibleBook(id: 12, name: '2 Reis', abbreviation: '2Rs', totalChapters: 25, isHebrew: true, category: 'history'),
    BibleBook(id: 13, name: '1 Crônicas', abbreviation: '1Cr', totalChapters: 29, isHebrew: true, category: 'history'),
    BibleBook(id: 14, name: '2 Crônicas', abbreviation: '2Cr', totalChapters: 36, isHebrew: true, category: 'history'),
    BibleBook(id: 15, name: 'Esdras', abbreviation: 'Esd', totalChapters: 10, isHebrew: true, category: 'history'),
    BibleBook(id: 16, name: 'Neemias', abbreviation: 'Ne', totalChapters: 13, isHebrew: true, category: 'history'),
    BibleBook(id: 17, name: 'Ester', abbreviation: 'Est', totalChapters: 10, isHebrew: true, category: 'history'),

    // 18-22 Livros Poéticos
    BibleBook(id: 18, name: 'Jó', abbreviation: 'Jó', totalChapters: 42, isHebrew: true, category: 'poetry'),
    BibleBook(id: 19, name: 'Salmos', abbreviation: 'Sal', totalChapters: 150, isHebrew: true, category: 'poetry'),
    BibleBook(id: 20, name: 'Provérbios', abbreviation: 'Pr', totalChapters: 31, isHebrew: true, category: 'poetry'),
    BibleBook(id: 21, name: 'Eclesiastes', abbreviation: 'Ec', totalChapters: 12, isHebrew: true, category: 'poetry'),
    BibleBook(id: 22, name: 'Cântico de Salomão', abbreviation: 'Cân', totalChapters: 8, isHebrew: true, category: 'poetry'),

    // 23-39 Profetas Maiores e Menores
    BibleBook(id: 23, name: 'Isaías', abbreviation: 'Is', totalChapters: 66, isHebrew: true, category: 'prophets'),
    BibleBook(id: 24, name: 'Jeremias', abbreviation: 'Je', totalChapters: 52, isHebrew: true, category: 'prophets'),
    BibleBook(id: 25, name: 'Lamentações', abbreviation: 'La', totalChapters: 5, isHebrew: true, category: 'prophets'),
    BibleBook(id: 26, name: 'Ezequiel', abbreviation: 'Ez', totalChapters: 48, isHebrew: true, category: 'prophets'),
    BibleBook(id: 27, name: 'Daniel', abbreviation: 'Da', totalChapters: 12, isHebrew: true, category: 'prophets'),
    BibleBook(id: 28, name: 'Oseias', abbreviation: 'Os', totalChapters: 14, isHebrew: true, category: 'prophets'),
    BibleBook(id: 29, name: 'Joel', abbreviation: 'Jl', totalChapters: 3, isHebrew: true, category: 'prophets'),
    BibleBook(id: 30, name: 'Amós', abbreviation: 'Am', totalChapters: 9, isHebrew: true, category: 'prophets'),
    BibleBook(id: 31, name: 'Obadias', abbreviation: 'Ob', totalChapters: 1, isHebrew: true, category: 'prophets'),
    BibleBook(id: 32, name: 'Jonas', abbreviation: 'Jon', totalChapters: 4, isHebrew: true, category: 'prophets'),
    BibleBook(id: 33, name: 'Miqueias', abbreviation: 'Miq', totalChapters: 7, isHebrew: true, category: 'prophets'),
    BibleBook(id: 34, name: 'Naum', abbreviation: 'Na', totalChapters: 3, isHebrew: true, category: 'prophets'),
    BibleBook(id: 35, name: 'Habacuque', abbreviation: 'Hab', totalChapters: 3, isHebrew: true, category: 'prophets'),
    BibleBook(id: 36, name: 'Sofonias', abbreviation: 'Sof', totalChapters: 3, isHebrew: true, category: 'prophets'),
    BibleBook(id: 37, name: 'Ageu', abbreviation: 'Ag', totalChapters: 2, isHebrew: true, category: 'prophets'),
    BibleBook(id: 38, name: 'Zacarias', abbreviation: 'Za', totalChapters: 14, isHebrew: true, category: 'prophets'),
    BibleBook(id: 39, name: 'Malaquias', abbreviation: 'Mal', totalChapters: 4, isHebrew: true, category: 'prophets'),

    // 40-43 Evangelhos
    BibleBook(id: 40, name: 'Mateus', abbreviation: 'Mt', totalChapters: 28, isHebrew: false, category: 'gospels'),
    BibleBook(id: 41, name: 'Marcos', abbreviation: 'Mr', totalChapters: 16, isHebrew: false, category: 'gospels'),
    BibleBook(id: 42, name: 'Lucas', abbreviation: 'Lu', totalChapters: 24, isHebrew: false, category: 'gospels'),
    BibleBook(id: 43, name: 'João', abbreviation: 'Jo', totalChapters: 21, isHebrew: false, category: 'gospels'),

    // 44 Atos
    BibleBook(id: 44, name: 'Atos', abbreviation: 'At', totalChapters: 28, isHebrew: false, category: 'acts'),

    // 45-65 Cartas
    BibleBook(id: 45, name: 'Romanos', abbreviation: 'Ro', totalChapters: 16, isHebrew: false, category: 'letters'),
    BibleBook(id: 46, name: '1 Coríntios', abbreviation: '1Co', totalChapters: 16, isHebrew: false, category: 'letters'),
    BibleBook(id: 47, name: '2 Coríntios', abbreviation: '2Co', totalChapters: 13, isHebrew: false, category: 'letters'),
    BibleBook(id: 48, name: 'Gálatas', abbreviation: 'Gál', totalChapters: 6, isHebrew: false, category: 'letters'),
    BibleBook(id: 49, name: 'Efésios', abbreviation: 'Ef', totalChapters: 6, isHebrew: false, category: 'letters'),
    BibleBook(id: 50, name: 'Filipenses', abbreviation: 'Fil', totalChapters: 4, isHebrew: false, category: 'letters'),
    BibleBook(id: 51, name: 'Colossenses', abbreviation: 'Col', totalChapters: 4, isHebrew: false, category: 'letters'),
    BibleBook(id: 52, name: '1 Tessalonicenses', abbreviation: '1Te', totalChapters: 5, isHebrew: false, category: 'letters'),
    BibleBook(id: 53, name: '2 Tessalonicenses', abbreviation: '2Te', totalChapters: 3, isHebrew: false, category: 'letters'),
    BibleBook(id: 54, name: '1 Timóteo', abbreviation: '1Ti', totalChapters: 6, isHebrew: false, category: 'letters'),
    BibleBook(id: 55, name: '2 Timóteo', abbreviation: '2Ti', totalChapters: 4, isHebrew: false, category: 'letters'),
    BibleBook(id: 56, name: 'Tito', abbreviation: 'Tit', totalChapters: 3, isHebrew: false, category: 'letters'),
    BibleBook(id: 57, name: 'Filêmon', abbreviation: 'Flm', totalChapters: 1, isHebrew: false, category: 'letters'),
    BibleBook(id: 58, name: 'Hebreus', abbreviation: 'Heb', totalChapters: 13, isHebrew: false, category: 'letters'),
    BibleBook(id: 59, name: 'Tiago', abbreviation: 'Tg', totalChapters: 5, isHebrew: false, category: 'letters'),
    BibleBook(id: 60, name: '1 Pedro', abbreviation: '1Pe', totalChapters: 5, isHebrew: false, category: 'letters'),
    BibleBook(id: 61, name: '2 Pedro', abbreviation: '2Pe', totalChapters: 3, isHebrew: false, category: 'letters'),
    BibleBook(id: 62, name: '1 João', abbreviation: '1Jo', totalChapters: 5, isHebrew: false, category: 'letters'),
    BibleBook(id: 63, name: '2 João', abbreviation: '2Jo', totalChapters: 1, isHebrew: false, category: 'letters'),
    BibleBook(id: 64, name: '3 João', abbreviation: '3Jo', totalChapters: 1, isHebrew: false, category: 'letters'),
    BibleBook(id: 65, name: 'Judas', abbreviation: 'Jd', totalChapters: 1, isHebrew: false, category: 'letters'),

    // 66 Apocalipse
    BibleBook(id: 66, name: 'Apocalipse', abbreviation: 'Re', totalChapters: 22, isHebrew: false, category: 'revelation'),
  ];

  static const List<BibleVersion> defaultVersions = [
    BibleVersion(
      id: 'nwt_t',
      pubCode: 'nwt',
      title: 'Tradução do Novo Mundo da Bíblia Sagrada',
      shortTitle: 'Tradução do Novo Mundo',
      languageName: 'Português (Brasil)',
      langCode: 'T',
      sizeLabel: '15 MB',
      sizeBytes: 14846651,
      directUrl: 'https://cfp2.jw-cdn.org/a/40194f/3/o/nwt_T.epub',
    ),
    BibleVersion(
      id: 'nwtsty_t',
      pubCode: 'nwtsty',
      title: 'Tradução do Novo Mundo da Bíblia Sagrada (Edição de Estudo)',
      shortTitle: 'Bíblia de Estudo',
      languageName: 'Português (Brasil)',
      langCode: 'T',
      sizeLabel: '120 MB',
      sizeBytes: 126325128,
      directUrl: 'https://cfp2.jw-cdn.org/a/5faae3/12/o/nwtsty_T.jwpub',
    ),
    BibleVersion(
      id: 'bi12_t',
      pubCode: 'bi12',
      title: 'Tradução do Novo Mundo das Escrituras Sagradas com Referências',
      shortTitle: 'Bíblia com Referências (1986)',
      languageName: 'Português (Brasil)',
      langCode: 'T',
      sizeLabel: '14 MB',
      sizeBytes: 3686238,
      directUrl: 'https://cfp2.jw-cdn.org/a/94ab7c/1/o/bi12_T.epub',
    ),
    BibleVersion(
      id: 'nwt_tpo',
      pubCode: 'nwt',
      title: 'Tradução do Novo Mundo da Bíblia Sagrada',
      shortTitle: 'Tradução do Novo Mundo (Portugal)',
      languageName: 'Português (Portugal)',
      langCode: 'TPO',
      sizeLabel: '15 MB',
      sizeBytes: 15825045,
      directUrl: 'https://cfp2.jw-cdn.org/a/9f7dec4/3/o/nwt_TPO.epub',
    ),
    BibleVersion(
      id: 'nwt_e',
      pubCode: 'nwt',
      title: 'New World Translation of the Holy Scriptures',
      shortTitle: 'New World Translation',
      languageName: 'English',
      langCode: 'E',
      sizeLabel: '15 MB',
      sizeBytes: 15600000,
      directUrl: 'https://cfp2.jw-cdn.org/a/40194f/3/o/nwt_E.epub',
    ),
    BibleVersion(
      id: 'nwt_s',
      pubCode: 'nwt',
      title: 'Traducción del Nuevo Mundo de las Santas Escrituras',
      shortTitle: 'Traducción del Nuevo Mundo',
      languageName: 'Español',
      langCode: 'S',
      sizeLabel: '15 MB',
      sizeBytes: 15900000,
      directUrl: 'https://cfp2.jw-cdn.org/a/40194f/3/o/nwt_S.epub',
    ),
  ];

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
      final exists = await vDir.exists();
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

  Future<bool> isVersionDownloaded(String versionId) async {
    final baseDir = await _getBiblesDirectory();
    final vDir = Directory(p.join(baseDir.path, versionId));
    return vDir.exists();
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

      final preferredFile = pub?.preferredFile(
        preferredLanguage: version.langCode,
        preferredFormats: const ['JWPUB', 'EPUB'],
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
          if (await nwtTDir.exists()) {
            await _copyDirectory(nwtTDir, targetDir);
          } else {
            final nwtPub = await client.getPublication(
              pubCode: 'nwt',
              language: version.langCode,
              fileFormat: 'JWPUB,EPUB',
            );
            final nwtFile = nwtPub?.preferredFile(preferredLanguage: version.langCode);
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
      return _generateOnlineOrPlaceholderChapter(book, chapter);
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
    }

    return _generateOnlineOrPlaceholderChapter(book, chapter);
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
      return null;
    }

    final xhtml = await foundFile.readAsString();
    return _parseXhtmlChapter(book, chapter, xhtml);
  }

  static const Map<int, String> _bi12BookAbbr = {
    1: 'GE', 2: 'EX', 3: 'LE', 4: 'NU', 5: 'DE',
    6: 'JOS', 7: 'JG', 8: 'RU', 9: '1SA', 10: '2SA',
    11: '1KI', 12: '2KI', 13: '1CH', 14: '2CH', 15: 'EZR',
    16: 'NE', 17: 'ES', 18: 'JOB', 19: 'PS', 20: 'PR',
    21: 'EC', 22: 'CA', 23: 'ISA', 24: 'JER', 25: 'LA',
    26: 'EZE', 27: 'DA', 28: 'HO', 29: 'JOE', 30: 'AM',
    31: 'OB', 32: 'JON', 33: 'MIC', 34: 'NA', 35: 'HAB',
    36: 'ZEP', 37: 'HAG', 38: 'ZEC', 39: 'MAL', 40: 'MT',
    41: 'MR', 42: 'LU', 43: 'JOH', 44: 'AC', 45: 'RO',
    46: '1CO', 47: '2CO', 48: 'GA', 49: 'EPH', 50: 'PHP',
    51: 'COL', 52: '1TH', 53: '2TH', 54: '1TI', 55: '2TI',
    56: 'TIT', 57: 'PHM', 58: 'HEB', 59: 'JAS', 60: '1PE',
    61: '2PE', 62: '1JO', 63: '2JO', 64: '3JO', 65: 'JUDE',
    66: 'RE',
  };

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

  BibleChapterContent _parseXhtmlChapter(
    BibleBook book,
    int chapter,
    String xhtml,
  ) {
    final verses = <BibleVerseItem>[];
    final footnotes = <String, String>{};

    // Extrai notas de rodapé do final se houver
    final footnoteMatches = RegExp(
      r'<li[^>]*id="(footnote\d+)"[^>]*>(.*?)</li>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(xhtml);

    for (final m in footnoteMatches) {
      final id = m.group(1) ?? '';
      final content = m.group(2)?.replaceAll(RegExp(r'<[^>]+>'), ' ').trim() ?? '';
      if (id.isNotEmpty) {
        footnotes[id] = content;
      }
    }

    // Extrai parágrafos que contenham versículos (prosa e poesia: sb, sl, sz, sp)
    final pMatches = RegExp(
      r'<p[^>]*class="[^"]*(?:sb|sl|sz|sp)[^"]*"[^>]*>(.*?)</p>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(xhtml);

    for (final pMatch in pMatches) {
      final pContent = pMatch.group(1) ?? '';

      // Versículo inicial ou marcador de versículos (ex: <span class="w_ch"><strong>1</strong></span> ou <sup>2</sup>)
      final parts = pContent.split(RegExp(
        r'(?:<span[^>]*class="w_ch"[^>]*><strong>\d+</strong>\s*</span>|(?:<strong><sup>\d+</sup></strong>|<sup><strong>\d+</strong></sup>))',
        caseSensitive: false,
      ));
      final numMatches = RegExp(
        r'(?:class="w_ch"[^>]*><strong>(\d+)</strong>|(?:<strong><sup>(\d+)</sup></strong>|<sup><strong>(\d+)</strong></sup>))',
        caseSensitive: false,
      ).allMatches(pContent).toList();

      if (numMatches.isEmpty && verses.isNotEmpty) {
        // Parágrafo de continuação do versículo anterior
        var contText = pContent
            .replaceAll(RegExp(r'<a[^>]*class="[^"]*(?:w_cr|w_fn)[^"]*"[^>]*>.*?</a>', caseSensitive: false), '')
            .replaceAll(RegExp(r'<span[^>]*class="pageNum"[^>]*>.*?</span>', caseSensitive: false, dotAll: true), '')
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAll('*', '')
            .trim();
        if (contText.isNotEmpty) {
          final lastVerse = verses.removeLast();
          verses.add(BibleVerseItem(
            verseNumber: lastVerse.verseNumber,
            text: '${lastVerse.text} $contText',
            footnotes: lastVerse.footnotes,
            crossRefs: lastVerse.crossRefs,
          ));
        }
        continue;
      }

      for (int i = 0; i < numMatches.length; i++) {
        final m = numMatches[i];
        final int vNum = m.group(1) != null
            ? 1
            : (int.tryParse(m.group(2) ?? m.group(3) ?? '') ?? (i + 1));
        final rawText = (i + 1 < parts.length) ? parts[i + 1] : '';

        // Limpa HTML mantendo apenas texto limpo
        var cleanText = rawText
            .replaceAll(RegExp(r'<a[^>]*class="[^"]*(?:w_cr|w_fn)[^"]*"[^>]*>.*?</a>', caseSensitive: false), '')
            .replaceAll(RegExp(r'<span[^>]*class="pageNum"[^>]*>.*?</span>', caseSensitive: false, dotAll: true), '')
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAll('*', '')
            .trim();

        if (cleanText.isNotEmpty) {
          verses.add(BibleVerseItem(
            verseNumber: vNum,
            text: cleanText,
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

  BibleChapterContent _generateOnlineOrPlaceholderChapter(
    BibleBook book,
    int chapter,
  ) {
    // Versículos essenciais pré-carregados para Gênesis 1 caso offline sem download prévio
    if (book.id == 1 && chapter == 1) {
      return BibleChapterContent(
        bookNumber: 1,
        bookName: 'Gênesis',
        chapterNumber: 1,
        verses: const [
          BibleVerseItem(verseNumber: 1, text: 'No princípio Deus criou os céus e a terra.'),
          BibleVerseItem(verseNumber: 2, text: 'A terra era vazia e deserta, e havia escuridão sobre as águas profundas; e a força ativa de Deus movia-se sobre as águas.'),
          BibleVerseItem(verseNumber: 3, text: 'E Deus disse: "Que haja luz." Então houve luz.'),
          BibleVerseItem(verseNumber: 4, text: 'Depois disso Deus viu que a luz era boa, e Deus começou a separar a luz da escuridão.'),
          BibleVerseItem(verseNumber: 5, text: 'Deus chamou a luz de "dia", mas a escuridão chamou de "noite". Houve noite e houve manhã, primeiro dia.'),
          BibleVerseItem(verseNumber: 6, text: 'Então Deus disse: "Haja uma expansão no meio das águas, e haja separação entre águas e águas."'),
          BibleVerseItem(verseNumber: 7, text: 'Deus passou então a fazer a expansão e a fazer separação entre as águas que deviam ficar debaixo da expansão e as águas que deviam ficar por cima da expansão. E assim se fez.'),
          BibleVerseItem(verseNumber: 8, text: 'E Deus começou a chamar a expansão de "Céus". E veio a ser noitinha e veio a ser manhã, segundo dia.'),
        ],
      );
    }

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
}
