import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentinela_study/services/bible_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BibleService Tests', () {
    late BibleService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          return Directory.systemTemp.path;
        },
      );
      service = BibleService();
    });

    test('Canonical list has exactly 66 books in biblical order', () {
      expect(BibleService.books.length, equals(66));
      expect(BibleService.books.first.id, equals(1));
      expect(BibleService.books.first.name, equals('Gênesis'));
      expect(BibleService.books.first.abbreviation, equals('Gên'));
      expect(BibleService.books.first.totalChapters, equals(50));
      expect(BibleService.books.first.isHebrew, isTrue);

      expect(BibleService.books.last.id, equals(66));
      expect(BibleService.books.last.name, equals('Apocalipse'));
      expect(BibleService.books.last.abbreviation, equals('Re'));
      expect(BibleService.books.last.totalChapters, equals(22));
      expect(BibleService.books.last.isHebrew, isFalse);
    });

    test('Books division: 39 Hebrew-Aramaic and 27 Christian Greek', () {
      final hebrew = BibleService.books.where((b) => b.isHebrew).toList();
      final greek = BibleService.books.where((b) => !b.isHebrew).toList();

      expect(hebrew.length, equals(39));
      expect(hebrew.last.name, equals('Malaquias'));

      expect(greek.length, equals(27));
      expect(greek.first.name, equals('Mateus'));
      expect(greek.last.name, equals('Apocalipse'));
    });

    test('Single-chapter books have totalChapters == 1', () {
      final singleChapBooks = BibleService.books.where((b) => b.totalChapters == 1).toList();
      expect(singleChapBooks.length, equals(5));
      final names = singleChapBooks.map((b) => b.name).toSet();
      expect(names, containsAll(['Obadias', 'Filêmon', '2 João', '3 João', 'Judas']));
    });

    test('Default catalog contains all Brazilian Portuguese Bibles including Study Bible and Reference Bible', () {
      final versions = BibleService.defaultVersions;
      // TNM 2015
      expect(versions.any((v) => v.id == 'nwt_t' && v.pubCode == 'nwt' && v.sizeLabel == '15 MB' && v.langCode == 'T'), isTrue);
      // Bíblia de Estudo
      expect(versions.any((v) => v.id == 'nwtsty_t' && v.pubCode == 'nwtsty' && v.sizeLabel == '120 MB' && v.langCode == 'T'), isTrue);
      // Bíblia com Referências (1986)
      expect(versions.any((v) => v.id == 'bi12_t' && v.pubCode == 'bi12' && v.sizeLabel == '14 MB' && v.langCode == 'T'), isTrue);
      // Portugal, English, Spanish
      expect(versions.any((v) => v.id == 'nwt_tpo' && v.langCode == 'TPO'), isTrue);
      expect(versions.any((v) => v.id == 'nwt_e' && v.langCode == 'E'), isTrue);
      expect(versions.any((v) => v.id == 'nwt_s' && v.langCode == 'S'), isTrue);
    });

    test('Active version defaults to nwt_t and can be updated', () async {
      final defaultId = await service.getActiveVersionId();
      expect(defaultId, equals('nwt_t'));

      await service.setActiveVersionId('nwt_e');
      final updatedId = await service.getActiveVersionId();
      expect(updatedId, equals('nwt_e'));
    });

    test('Fallback chapter loader generates Genesis 1 verses', () async {
      final genesis = BibleService.books.first;
      final chapterData = await service.loadChapter(genesis, 1);

      expect(chapterData.bookNumber, equals(1));
      expect(chapterData.chapterNumber, equals(1));
      expect(chapterData.verses.isNotEmpty, isTrue);
      expect(chapterData.verses.first.verseNumber, equals(1));
      expect(chapterData.verses.first.text, contains('No princípio Deus criou os céus e a terra.'));
    });
    test('parseXhtmlChapter parses prose with multiple verses and footnotes', () {
      final genesis = BibleService.books.first;
      const sampleXhtml = '''
        <html>
          <body>
            <p class="sb"><span class="w_ch"><strong>1</strong></span> No princípio Deus criou os céus e a terra.*</p>
            <p class="sb"><strong><sup>2</sup></strong> A terra era sem forma e vazia.*</p>
            <ol>
              <li id="footnote1">Nota explicativa de Gênesis 1:1</li>
            </ol>
          </body>
        </html>
      ''';

      final content = service.parseXhtmlChapter(genesis, 1, sampleXhtml);
      expect(content.verses.length, equals(2));
      expect(content.verses[0].verseNumber, equals(1));
      expect(content.verses[0].text, equals('No princípio Deus criou os céus e a terra.'));
      expect(content.verses[1].verseNumber, equals(2));
      expect(content.verses[1].text, equals('A terra era sem forma e vazia.'));
      expect(content.footnotes.containsKey('footnote1'), isTrue);
      expect(content.footnotes['footnote1'], contains('Nota explicativa de Gênesis 1:1'));
    });

    test('parseXhtmlChapter parses poetic books (Psalms) with sl, sz classes and multiline continuation', () {
      final psalms = BibleService.books.firstWhere((b) => b.name == 'Salmos');
      const samplePoetryXhtml = '''
        <html>
          <body>
            <p class="sl"><span class="w_ch"><strong>23</strong></span> O Senhor é o meu Pastor.</p>
            <p class="sz">Nada me faltará.</p>
            <p class="sl"><strong><sup>2</sup></strong> Ele me faz deitar em verdes pastagens;</p>
            <p class="sz">Guia-me a lugares de descanso bem regados.</p>
          </body>
        </html>
      ''';

      final content = service.parseXhtmlChapter(psalms, 23, samplePoetryXhtml);
      expect(content.verses.length, equals(2));
      expect(content.verses[0].verseNumber, equals(1)); // Chapter marker in MEPS designates Verse 1
      expect(content.verses[0].text, equals('O Senhor é o meu Pastor. Nada me faltará.'));
      expect(content.verses[1].verseNumber, equals(2));
      expect(content.verses[1].text, contains('Ele me faz deitar em verdes pastagens; Guia-me a lugares de descanso bem regados.'));
    });


    test('parseXhtmlChapter correctly identifies verse 1 from chapter number in subsequent chapters (Genesis 2)', () {
      final genesis = BibleService.books.first;
      const gen2Xhtml = '''
        <html>
          <body>
            <p class="sb"><span class="w_ch"><strong>2</strong></span> Assim foram terminados os céus e a terra.*</p>
            <p class="sb"><strong><sup>2</sup></strong> No sétimo dia Deus havia terminado a sua obra.*</p>
          </body>
        </html>
      ''';

      final content = service.parseXhtmlChapter(genesis, 2, gen2Xhtml);
      expect(content.verses.length, equals(2));
      expect(content.verses[0].verseNumber, equals(1));
      expect(content.verses[0].text, equals('Assim foram terminados os céus e a terra.'));
      expect(content.verses[1].verseNumber, equals(2));
      expect(content.verses[1].text, equals('No sétimo dia Deus havia terminado a sua obra.'));
    });

    test('deleteVersion removes version directory if it exists', () async {
      final versions = await service.getVersions();
      expect(versions.isNotEmpty, isTrue);

      await service.deleteVersion('non_existent_version_123');
      final isDownloaded = await service.isVersionDownloaded('non_existent_version_123');
      expect(isDownloaded, isFalse);
    });

    test('deleteVersion defends against path traversal parameters', () async {
      // Must safely reject/ignore paths traversing outside the bibles folder
      await service.deleteVersion('../../unauthorized_directory');
      // Should not throw or crash
    });

    test('parseXhtmlChapter strips cross-references without leaving residual plus characters', () {
      final genesis = BibleService.books.first;
      const xhtmlWithRefs = '''
        <html>
          <body>
            <p class="sb"><span class="w_ch"><strong>1</strong></span> No princípio Deus criou os céus e a terra.<a class="w_cr" href="#cr1">+</a></p>
            <p class="sb"><sup><strong>2</strong></sup> A terra era sem forma e vazia.<a class="w_fn" href="#fn1">*</a></p>
          </body>
        </html>
      ''';

      final content = service.parseXhtmlChapter(genesis, 1, xhtmlWithRefs);
      expect(content.verses.length, equals(2));
      expect(content.verses[0].verseNumber, equals(1));
      expect(content.verses[0].text, equals('No princípio Deus criou os céus e a terra.'));
      expect(content.verses[0].text.contains('+'), isFalse);

      expect(content.verses[1].verseNumber, equals(2));
      expect(content.verses[1].text, equals('A terra era sem forma e vazia.'));
      expect(content.verses[1].text.contains('*'), isFalse);
    });

    test('parseXhtmlChapter creates interactive BibleVerseToken for footnotes and cross-references', () {
      final genesis = BibleService.books.first;
      const xhtmlWithRefs = '''
        <html>
          <body>
            <p class="sb"><span class="w_ch"><strong>1</strong></span> No princípio Deus criou os céus e a terra.<a class="w_cr" href="#cr1">+</a></p>
            <p class="sb"><sup><strong>2</strong></sup> A terra era sem forma e vazia.<a class="w_fn" href="#fn1">*</a></p>
            <ol>
              <li id="fn1">Nota explicativa sobre o estado primordial.</li>
            </ol>
          </body>
        </html>
      ''';

      final content = service.parseXhtmlChapter(genesis, 1, xhtmlWithRefs);
      expect(content.verses[0].tokens.any((t) => t.isCrossRef && t.crossRefTarget == '#cr1'), isTrue);
      expect(content.verses[1].tokens.any((t) => t.isFootnote && t.footnoteId == 'fn1' && (t.footnoteText?.contains('estado primordial') ?? false)), isTrue);
    });

    test('parseXhtmlChapter supports sup without strong and maintains spacing on continuation paragraphs', () {
      final genesis = BibleService.books.first;
      const xhtmlSup = '''
        <html>
          <body>
            <p class="sb"><span class="w_ch"><strong>1</strong></span> No princípio Deus criou os céus e a terra.</p>
            <p class="sb"><sup>2</sup> A terra era sem forma e vazia.</p>
            <p class="sz">E havia escuridão sobre a superfície das águas profundas.</p>
          </body>
        </html>
      ''';

      final content = service.parseXhtmlChapter(genesis, 1, xhtmlSup);
      expect(content.verses.length, equals(2));
      expect(content.verses[1].verseNumber, equals(2));
      expect(content.verses[1].text, contains('A terra era sem forma e vazia. E havia escuridão'));
      final tokenTexts = content.verses[1].tokens.map((t) => t.text).join();
      expect(tokenTexts, contains('A terra era sem forma e vazia. E havia escuridão'));
    });
  });
}
