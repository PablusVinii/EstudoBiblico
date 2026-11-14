import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/article.dart';
import 'study_storage_service.dart';

class ArticleParser {
  /// Extrai as imagens do arquivo EPUB para um diretório local e retorna um mapa [nomeArquivo -> caminhoAbsoluto]
  static Future<Map<String, String>> _extractImages(Archive archive, String issueCode) async {
    final imageMap = <String, String>{};
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'issues', 'extracted_images', issueCode));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      for (final file in archive) {
        if (!file.isFile) continue;
        final lower = file.name.toLowerCase();
        if (lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp')) {
          final baseName = p.basename(file.name);
          final targetPath = p.join(imagesDir.path, baseName);
          final targetFile = File(targetPath);

          if (!await targetFile.exists()) {
            await targetFile.writeAsBytes(file.content as List<int>);
          }
          imageMap[baseName] = targetPath;
        }
      }
    } catch (_) {}
    return imageMap;
  }

  /// Faz o parse completo da edição, extraindo imagens de capa, período de estudo e artigos
  static Future<ParsedIssue> parseIssue(String epubPath, [String? explicitIssueCode]) async {
    final bytes = await File(epubPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final issueCode = explicitIssueCode ??
        p.basenameWithoutExtension(epubPath).replaceAll(RegExp(r'[^0-9]'), '');

    final imageMap = await _extractImages(archive, issueCode);

    String issueTitle = 'A Sentinela $issueCode';
    String? studyPeriod;
    String? coverImagePath;

    final articles = <StudyArticle>[];
    final tocDatesByHref = <String, String>{};

    // 1. Procura arquivo de capa / sumário / TOC
    for (final file in archive) {
      if (file.isFile && (file.name.endsWith('.xhtml') || file.name.endsWith('.html'))) {
        final content = utf8.decode(file.content as List<int>, allowMalformed: true);
        final lower = file.name.toLowerCase();

        // Extrai datas associadas aos artigos no sumário (TOC)
        final tocMatches = RegExp(
          r'<h3[^>]*>(?:Estudo\s+\d+\s*[ǀ|]\s*)?(.*?)<\/h3>\s*<p[^>]*>[^<]*<a\s+href="([^"]+)"',
          caseSensitive: false,
          dotAll: true,
        ).allMatches(content);
        for (final tm in tocMatches) {
          final dateText = _cleanHtml(tm.group(1)!);
          final href = p.basename(tm.group(2)!.split('#').first);
          if (dateText.isNotEmpty && href.isNotEmpty) {
            tocDatesByHref[href] = dateText;
          }
        }

        if (lower.contains('cover') ||
            lower.contains('toc') ||
            content.contains('ARTIGOS DE ESTUDO') ||
            content.contains('Estudos para as semanas') ||
            content.contains('NESTA REVISTA') ||
            content.contains('class="coverTtl"')) {
          final imgMatch = RegExp(r'<img[^>]*src="([^"]+)"', dotAll: true).firstMatch(content);
          if (imgMatch != null) {
            final base = p.basename(imgMatch.group(1)!);
            coverImagePath = imageMap[base];
          }

          final periodMatch = RegExp(
            r'(?:ARTIGOS DE ESTUDO PARA AS SEMANAS DE:|Estudos para as semanas de)\s*(.*?)<\/h\d>',
            caseSensitive: false,
            dotAll: true,
          ).firstMatch(content);
          if (periodMatch != null) {
            studyPeriod = 'Estudos para as semanas de ${_cleanHtml(periodMatch.group(1)!)}';
          }

          final monthMatch = RegExp(r'<h2[^>]*><strong>([A-ZÇÃÕ\s\d]+)<\/strong><\/h2>', dotAll: true).firstMatch(content);
          if (monthMatch != null) {
            issueTitle = 'A Sentinela, ${_cleanHtml(monthMatch.group(1)!).toLowerCase()}';
          }
        }
      }
    }

    // 2. Extrai artigos de estudo
    for (final file in archive) {
      if (file.isFile && (file.name.endsWith('.xhtml') || file.name.endsWith('.html'))) {
        final lowerName = file.name.toLowerCase();
        if (lowerName.contains('cover') ||
            lowerName.contains('toc') ||
            lowerName.contains('pagenav') ||
            lowerName.contains('-extracted')) {
          continue;
        }

        final content = utf8.decode(file.content as List<int>, allowMalformed: true);

        if (content.contains('class="qu"') ||
            content.contains('id="q') ||
            content.contains('data-pnum=') ||
            content.contains('class="contextTtl"')) {
          final baseName = p.basename(file.name);
          final tocDate = tocDatesByHref[baseName];
          final article = await _parseHtmlArticle(file.name, content, imageMap, tocDate);
          if (article != null && article.paragraphs.isNotEmpty) {
            articles.add(article);
          }
        }
      }
    }

    return ParsedIssue(
      issueCode: issueCode,
      title: issueTitle,
      studyPeriod: studyPeriod,
      coverImagePath: coverImagePath,
      articles: articles,
    );
  }

  @visibleForTesting
  static Future<StudyArticle?> parseHtmlArticle(
    String fileName,
    String html,
    Map<String, String> imageMap, [
    String? tocDate,
  ]) => _parseHtmlArticle(fileName, html, imageMap, tocDate);

  static Future<StudyArticle?> _parseHtmlArticle(
    String fileName,
    String html,
    Map<String, String> imageMap, [
    String? tocDate,
  ]) async {
    // Remove notas de rodapé e textos marginais anexados ao final do artigo
    html = html.replaceAll(RegExp(r'<aside[^>]*>.*?<\/aside>', dotAll: true), '');
    html = html.replaceAll(RegExp(r'<div[^>]*class="[^"]*(?:groupExt|groupFootnote)[^"]*"[^>]*>.*?<\/div>', dotAll: true), '');

    // 1. Data da Semana (ex: 7 A 13 DE SETEMBRO DE 2026 ou vinda do TOC em edições antigas)
    String? weekDate;
    final dateMatch = RegExp(r'class="[^"]*contextTtl[^"]*"[^>]*>(.*?)<\/p>', dotAll: true).firstMatch(html) ??
        RegExp(r'<p[^>]*>\s*<strong>(\d+\s+(?:A|-)\s+\d+\s+DE\s+[A-ZÇÃÕ]+\s+DE\s+\d{4})<\/strong>', dotAll: true).firstMatch(html);
    if (dateMatch != null) {
      final rawDate = _cleanHtml(dateMatch.group(1)!);
      if (!rawDate.toUpperCase().startsWith('ESTUDO') || tocDate == null) {
        weekDate = rawDate;
      } else {
        weekDate = tocDate;
      }
    } else if (tocDate != null) {
      weekDate = tocDate;
    }

    // 2. Cântico (ex: CÂNTICO 88 Os teus caminhos quero entender)
    String? song;
    final songMatch = RegExp(r'class="[^"]*pubRefs[^"]*"[^>]*>.*?href="[^"]*extracted[^"]*"><strong>(CÂNTICO\s+\d+)<\/strong><\/a>\s*(.*?)<\/p>', dotAll: true).firstMatch(html) ??
        RegExp(r'(CÂNTICO\s+\d+[^<\n\r]*)', dotAll: true).firstMatch(html);
    if (songMatch != null) {
      if (songMatch.groupCount >= 2 && songMatch.group(2) != null) {
        song = '${_cleanHtml(songMatch.group(1)!)} ${_cleanHtml(songMatch.group(2)!)}';
      } else {
        song = _cleanHtml(songMatch.group(1)!);
      }
    }

    // 3. Título do Artigo
    final titleMatch = RegExp(r'<h1[^>]*>(.*?)<\/h1>', dotAll: true).firstMatch(html);
    final title = titleMatch != null ? _cleanHtml(titleMatch.group(1)!) : 'Artigo de Estudo';

    // 4. Texto Temático (ex: “Os habitantes de Gibeão tinham feito paz com Israel...” — JOS. 10:1.)
    String? themeScripture;
    final themeMatch = RegExp(r'class="[^"]*themeScrp[^"]*"[^>]*>(.*?)<\/p>', dotAll: true).firstMatch(html);
    if (themeMatch != null) {
      themeScripture = _cleanHtml(themeMatch.group(1)!);
    }

    // 5. Objetivo Oficial
    String? objective;
    final objMatch = RegExp(r'<strong>OBJETIVO<\/strong><\/p>\s*<p[^>]*class="[^"]*pubRefs[^"]*"[^>]*>(.*?)<\/p>', dotAll: true).firstMatch(html) ??
        RegExp(r'<strong>OBJETIVO<\/strong><\/p>\s*<p[^>]*>(.*?)<\/p>', dotAll: true).firstMatch(html);
    if (objMatch != null) {
      objective = _cleanHtml(objMatch.group(1)!);
    }

    // 6. Extração de ilustrações e legendas
    final figureRegex = RegExp(
      r'<figure[^>]*>\s*<img\s+[^>]*src="([^"]+)"[^>]*>\s*(?:<figcaption[^>]*>(.*?)<\/figcaption>)?\s*<\/figure>',
      dotAll: true,
    );

    final figuresByPara = <int, Map<String, String>>{};
    String? leadImagePath;

    for (final fm in figureRegex.allMatches(html)) {
      final src = fm.group(1) ?? '';
      final baseName = p.basename(src);
      final localPath = imageMap[baseName];
      final captionRaw = fm.group(2) ?? '';
      final caption = _cleanHtml(captionRaw);

      if (leadImagePath == null && localPath != null) {
        leadImagePath = localPath;
      }

      if (localPath != null) {
        final paraRefMatch = RegExp(r'par[áa]grafos?\s+(\d+)(?:\s*(?:e|,|-)\s*(\d+))?', caseSensitive: false).firstMatch(caption);
        if (paraRefMatch != null) {
          final targetNum1 = int.tryParse(paraRefMatch.group(1)!);
          if (targetNum1 != null) {
            figuresByPara[targetNum1] = {'path': localPath, 'caption': caption};
          }
          if (paraRefMatch.group(2) != null) {
            final targetNum2 = int.tryParse(paraRefMatch.group(2)!);
            if (targetNum2 != null) {
              figuresByPara[targetNum2] = {'path': localPath, 'caption': caption};
            }
          }
        }
      }
    }

    // 7. Extração dos Itens de Estudo em Sequência Linear Estrita
    final tagRegex = RegExp(
      r'(?:<h2[^>]*>(.*?)<\/h2>)|(?:<p[^>]*class="qu"[^>]*>(.*?)<\/p>)|(?:<p[^>]*id="q\d+"[^>]*>(.*?)<\/p>)|(?:<p[^>]*>(.*?)<\/p>)',
      dotAll: true,
    );
    final matches = tagRegex.allMatches(html);

    final paragraphs = <StudyParagraph>[];
    String? pendingHeading;
    String? pendingQuestion;
    String? pendingQuestionNum;

    // Carrega dados persistidos do usuário
    final savedData = await StudyStorageService.loadArticleData(fileName);

    for (final m in matches) {
      final fullMatch = m.group(0) ?? '';

      // A. Subtítulo (h2)
      if (fullMatch.startsWith('<h2')) {
        final cleanH = _cleanHtml(m.group(1) ?? '');
        if (cleanH.isNotEmpty) {
          pendingHeading = cleanH;
        }
        continue;
      }

      // B. Pergunta de Estudo (class="qu" ou id="q...")
      if (fullMatch.contains('class="qu"') || fullMatch.contains('id="q')) {
        final cleanQ = _cleanHtml(m.group(2) ?? m.group(3) ?? fullMatch);
        if (cleanQ.isNotEmpty) {
          pendingQuestion = cleanQ;
          final qm = RegExp(r'^\s*(\d+(?:[–-]\d+)?\.?)\s*').firstMatch(cleanQ);
          pendingQuestionNum = qm?.group(1);
        }
        continue;
      }

      // C. Ignora metadados e elementos de navegação
      if (fullMatch.contains('class="contextTtl"') ||
          fullMatch.contains('class="themeScrp"') ||
          fullMatch.contains('class="pubRefs"') ||
          fullMatch.contains('class="pageNum"') ||
          fullMatch.contains('class="extScrpCite"')) {
        continue;
      }

      // D. Determina o número do parágrafo (compatível com 2022+ e edições legadas 2021 para trás)
      int? paraNum;
      final pnumMatch = RegExp(r'data-pnum="(\d+)"').firstMatch(fullMatch);
      if (pnumMatch != null) {
        paraNum = int.parse(pnumMatch.group(1)!);
      } else {
        final supMatch = RegExp(r'<strong><sup>\s*(\d+)').firstMatch(fullMatch);
        if (supMatch != null) {
          paraNum = int.parse(supMatch.group(1)!);
        } else if (paragraphs.isEmpty && (pendingQuestionNum?.startsWith('1') ?? false)) {
          paraNum = 1;
        } else if (fullMatch.contains('data-rel-pid') || fullMatch.contains('class="p')) {
          paraNum = paragraphs.isNotEmpty ? paragraphs.last.number + 1 : 1;
        }
      }

      if (paraNum == null) continue;

      // Limpa tags e número inicial se estiver colado
      String text = _cleanHtml(m.group(4) ?? fullMatch);
      text = text.replaceAll(RegExp(r'<span[^>]*class="pageNum"[^>]*>.*?<\/span>', dotAll: true), '');
      text = text.replaceFirst(RegExp(r'^\s*<strong><sup>\s*\d+\s*<\/sup><\/strong>\s*'), '');
      text = text.replaceFirst(RegExp(r'^\s*\d+\s*'), '').trim();
      if (text.isEmpty) continue;

      final figInfo = figuresByPara[paraNum];
      final pSaved = savedData[paraNum];
      final savedAnswer = pSaved?['answer'] ?? '';
      final savedKeyPoint = pSaved?['keyPoint'];

      paragraphs.add(StudyParagraph(
        number: paraNum,
        text: text,
        questionNumber: pendingQuestionNum,
        question: pendingQuestion,
        headingBefore: pendingHeading,
        illustrationPath: figInfo?['path'],
        illustrationCaption: figInfo?['caption'],
        userAnswer: savedAnswer,
        highlightedKeyPoint: savedKeyPoint,
      ));

      // Reseta o heading para não duplicar nos parágrafos seguintes
      pendingHeading = null;
    }

    if (paragraphs.isEmpty) return null;

    return StudyArticle(
      id: fileName,
      title: title,
      weekDate: weekDate,
      song: song,
      themeScripture: themeScripture,
      objective: objective,
      leadImagePath: leadImagePath,
      paragraphs: paragraphs,
    );
  }

  static String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
