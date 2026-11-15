import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sentinela_study/services/jwpub_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('JwpubService Key Derivation & Cryptography Tests', () {
    test('Derives exact Key and IV matching reverse-engineered reference', () {
      // Base: language=1, symbol=mi26, year=2026 -> "1_mi26_2026"
      final result = JwpubService.deriveKeyAndIv(
        languageIndex: 1,
        symbol: 'mi26',
        year: 2026,
      );

      final expectedKeyHex = 'dfca8f5c29d215401e104169e4c7e356';
      final expectedIvHex = 'ce4b41b8086ff971df292d5dfad51a52';

      expect(result.keyHex, equals(expectedKeyHex));
      expect(result.ivHex, equals(expectedIvHex));
      expect(result.key.length, equals(16));
      expect(result.iv.length, equals(16));
    });

    test('Derives key with issueTagNumber for periodicals', () {
      final result = JwpubService.deriveKeyAndIv(
        languageIndex: 4,
        symbol: 'w',
        year: 2026,
        issueTagNumber: 202607,
      );

      expect(result.key.length, equals(16));
      expect(result.iv.length, equals(16));
      expect(result.keyHex.isNotEmpty, isTrue);
    });

    test('Encrypts and decrypts HTML content via AES-128-CBC and Zlib roundtrip', () {
      final keys = JwpubService.deriveKeyAndIv(
        languageIndex: 1,
        symbol: 'mi26',
        year: 2026,
      );

      const originalHtml = '<!DOCTYPE html><html><body><p id="p1" data-pid="1">Estudo bíblico oficial</p></body></html>';

      final encrypted = JwpubService.encryptContent(
        html: originalHtml,
        key: keys.key,
        iv: keys.iv,
      );

      expect(encrypted.isNotEmpty, isTrue);

      final decrypted = JwpubService.decryptContent(
        encryptedBytes: encrypted,
        key: keys.key,
        iv: keys.iv,
      );

      expect(decrypted, equals(originalHtml));
    });

    test('Extracts plain paragraphs from decrypted HTML', () {
      const html = '''
        <div>
          <p class="theme">Artigo de Estudo</p>
          <p id="p1" data-pid="1">Primeiro parágrafo de introdução.</p>
          <p id="p2" data-pid="2">Segundo parágrafo com <span>texto formatado</span>.</p>
        </div>
      ''';

      final paragraphs = JwpubService.extractPlainParagraphs(html);
      expect(paragraphs.length, equals(3));
      expect(paragraphs[0], equals('Artigo de Estudo'));
      expect(paragraphs[1], equals('Primeiro parágrafo de introdução.'));
      expect(paragraphs[2], equals('Segundo parágrafo com texto formatado.'));
    });
  });

  group('JwpubService SQLite and Document Tests', () {
    test('Opens JWPUB database and queries Document and DatedText rows with decryption', () async {
      final tempDir = await Directory.systemTemp.createTemp('jwpub_test_');
      final dbPath = '${tempDir.path}/test_symbol.db';

      final db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE Document (
              DocumentId INTEGER PRIMARY KEY,
              MepsDocumentId INTEGER,
              Title TEXT,
              TocTitle TEXT,
              ChapterNumber INTEGER,
              ParagraphCount INTEGER,
              ContentLength INTEGER,
              Content BLOB
            )
          ''');

          await db.execute('''
            CREATE TABLE DatedText (
              DatedTextId INTEGER PRIMARY KEY,
              DocumentId INTEGER,
              Link TEXT,
              FirstDateOffset INTEGER,
              LastDateOffset INTEGER,
              Caption TEXT
            )
          ''');
        },
      );

      const manifest = JwpubManifest(
        name: 'A Sentinela',
        symbol: 'w26',
        year: 2026,
        language: 5,
        publicationType: 'Watchtower',
        dbFileName: 'test_symbol.db',
        issueNumber: 1,
      );

      final keys = JwpubService.deriveKeyAndIv(
        languageIndex: manifest.language,
        symbol: manifest.symbol,
        year: manifest.year,
        issueTagNumber: manifest.issueNumber,
      );

      const articleHtml = '''
        <html><body>
          <h2>Artigo Principal</h2>
          <p id="p1" data-pid="1">Como Jeová nos consola em todas as aflições.</p>
        </body></html>
      ''';

      final encryptedBlob = JwpubService.encryptContent(
        html: articleHtml,
        key: keys.key,
        iv: keys.iv,
      );

      await db.insert('Document', {
        'DocumentId': 1,
        'MepsDocumentId': 2026240,
        'Title': 'Continue cuidando da sua necessidade espiritual',
        'TocTitle': 'Artigo 1',
        'ChapterNumber': 1,
        'ParagraphCount': 20,
        'ContentLength': encryptedBlob.length,
        'Content': encryptedBlob,
      });

      await db.insert('DatedText', {
        'DatedTextId': 1,
        'DocumentId': 1,
        'Link': 'p/T:2026247/3-4',
        'FirstDateOffset': 20260302,
        'LastDateOffset': 20260308,
        'Caption': 'Estudo para 2 a 8 de março',
      });

      final openedDb = await JwpubService.openJwpubDatabase(tempDir, 'test_symbol.db');
      final docs = await JwpubService.readDocuments(db: openedDb, manifest: manifest);
      final dated = await JwpubService.readDatedTexts(openedDb);

      expect(docs.length, equals(1));
      expect(docs.first.documentId, equals(1));
      expect(docs.first.title, contains('necessidade espiritual'));
      expect(docs.first.contentHtml, contains('Como Jeová nos consola'));
      expect(docs.first.plainParagraphs.isNotEmpty, isTrue);

      expect(dated.length, equals(1));
      expect(dated.first.firstDateOffset, equals(20260302));
      expect(dated.first.caption, contains('2 a 8 de março'));

      await openedDb.close();
      await db.close();
      await tempDir.delete(recursive: true);
    });

    test('Parses JwpubManifest from JSON', () {
      final json = {
        'name': 'A Sentinela',
        'publication': {
          'symbol': 'w26',
          'year': 2026,
          'language': 5,
          'publicationType': 'Watchtower',
          'fileName': 'w_T_202601.db',
          'issueNumber': 1,
          'issueProperties': {
            'coverTitle': 'Estudos para março',
            'symbol': 'w26.01'
          }
        }
      };

      final manifest = JwpubManifest.fromJson(json);
      expect(manifest.name, equals('A Sentinela'));
      expect(manifest.symbol, equals('w26'));
      expect(manifest.year, equals(2026));
      expect(manifest.language, equals(5));
      expect(manifest.issueNumber, equals(1));
      expect(manifest.coverTitle, equals('Estudos para março'));
    });
  });

  group('JwpubService URI Schemes Tests', () {
    test('Parses single verse Bible citation URL', () {
      final parsed = JwpubService.parseBibleLink('jwpub://b/NWTR/40:24:14');
      expect(parsed, isNotNull);
      expect(parsed!.bookNumber, equals(40));
      expect(parsed.chapter, equals(24));
      expect(parsed.startVerse, equals(14));
      expect(parsed.endVerse, equals(14));
      expect(parsed.bookName, equals('Mateus'));
    });

    test('Parses verse range Bible citation URL', () {
      final parsed = JwpubService.parseBibleLink('jwpub://b/NWTR/19:23:1-19:23:6');
      expect(parsed, isNotNull);
      expect(parsed!.bookNumber, equals(19));
      expect(parsed.chapter, equals(23));
      expect(parsed.startVerse, equals(1));
      expect(parsed.endVerse, equals(6));
      expect(parsed.bookName, equals('Salmos'));
    });

    test('Parses Genesis 1:1', () {
      final parsed = JwpubService.parseBibleLink('jwpub://b/NWTR/1:1:1');
      expect(parsed, isNotNull);
      expect(parsed!.bookNumber, equals(1));
      expect(parsed.chapter, equals(1));
      expect(parsed.startVerse, equals(1));
      expect(parsed.bookName, equals('Gênesis'));
    });

    test('Parses Revelation 21:3-4', () {
      final parsed = JwpubService.parseBibleLink('jwpub://b/NWTR/66:21:3-66:21:4');
      expect(parsed, isNotNull);
      expect(parsed!.bookNumber, equals(66));
      expect(parsed.chapter, equals(21));
      expect(parsed.startVerse, equals(3));
      expect(parsed.endVerse, equals(4));
      expect(parsed.bookName, equals('Apocalipse'));
    });

    test('Parses internal document link', () {
      final parsed = JwpubService.parseInternalLink('jwpub://p/T:46500105/');
      expect(parsed, isNotNull);
      expect(parsed!.lang, equals('T'));
      expect(parsed.documentId, equals(46500105));
    });

    test('Returns null on invalid URLs', () {
      expect(JwpubService.parseBibleLink('https://example.com'), isNull);
      expect(JwpubService.parseInternalLink('invalid_link'), isNull);
    });
  });
}
