import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela_study/services/jwpub_service.dart';

void main() {
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
