import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela_study/services/bible_citation_parser.dart';

void main() {
  group('BibleCitationParser Tests', () {
    test('Parses classic chapter and verse citation (Salmo 23:1)', () {
      final res = BibleCitationParser.parse('Salmo 23:1');
      expect(res, isNotNull);
      expect(res!.book.name, equals('Salmos'));
      expect(res.book.id, equals(19));
      expect(res.chapter, equals(23));
      expect(res.startVerse, equals(1));
      expect(res.endVerse, equals(1));
    });

    test('Parses verse range (1 Coríntios 13:4-8)', () {
      final res = BibleCitationParser.parse('1 Coríntios 13:4-8');
      expect(res, isNotNull);
      expect(res!.book.name, equals('1 Coríntios'));
      expect(res.book.id, equals(46));
      expect(res.chapter, equals(13));
      expect(res.startVerse, equals(4));
      expect(res.endVerse, equals(8));
    });

    test('Parses comma separated verse range (Gênesis 1:1, 2)', () {
      final res = BibleCitationParser.parse('Gênesis 1:1, 2');
      expect(res, isNotNull);
      expect(res!.book.name, equals('Gênesis'));
      expect(res.book.id, equals(1));
      expect(res.chapter, equals(1));
      expect(res.startVerse, equals(1));
      expect(res.endVerse, equals(2));
    });

    test('Parses abbreviated books with dot (Mat. 24:14, Rev. 21:3, 4)', () {
      final res1 = BibleCitationParser.parse('Mat. 24:14');
      expect(res1, isNotNull);
      expect(res1!.book.name, equals('Mateus'));
      expect(res1.chapter, equals(24));
      expect(res1.startVerse, equals(14));

      final res2 = BibleCitationParser.parse('Rev. 21:3, 4');
      expect(res2, isNotNull);
      expect(res2!.book.name, equals('Apocalipse'));
      expect(res2.chapter, equals(21));
      expect(res2.startVerse, equals(3));
      expect(res2.endVerse, equals(4));
    });

    test('Parses single-chapter books without colon (Judas 4)', () {
      final res = BibleCitationParser.parse('Judas 4');
      expect(res, isNotNull);
      expect(res!.book.name, equals('Judas'));
      expect(res.book.id, equals(65));
      expect(res.chapter, equals(1));
      expect(res.startVerse, equals(4));
      expect(res.endVerse, equals(4));
    });

    test('Parses whole chapter citation (Salmo 23)', () {
      final res = BibleCitationParser.parse('Salmo 23');
      expect(res, isNotNull);
      expect(res!.book.name, equals('Salmos'));
      expect(res.chapter, equals(23));
      expect(res.startVerse, equals(1));
    });

    test('Matches citations with accented initial letters like Êxodo (Êxo. 12:5, 7)', () {
      final text = 'casas. (Êxo. 12:5, 7) Se fizessem isso... (Êxo. 8:25-27) ordenado. (Êxo. 12:28)';
      final matches = BibleCitationParser.citationRegex.allMatches(text).toList();
      expect(matches.length, equals(3));
      expect(matches[0].group(1), equals('Êxo'));
      expect(matches[1].group(1), equals('Êxo'));
      expect(matches[2].group(1), equals('Êxo'));
    });

    test('Extracts cross-chapter ranges (2 Sam. 16:23–17:2)', () {
      final spans = BibleCitationParser.extractScriptureSpans('(2 Sam. 16:23–17:2; Sal. 55:12-14)');
      expect(spans.length, equals(2));
      expect(spans[0].scripture.rawCitation, equals('2 Sam. 16:23–17:2'));
      expect(spans[0].scripture.book.name, equals('2 Samuel'));
      expect(spans[0].scripture.chapter, equals(16));
      expect(spans[0].scripture.startVerse, equals(23));
      expect(spans[0].scripture.endChapter, equals(17));
      expect(spans[0].scripture.endVerse, equals(2));

      expect(spans[1].scripture.rawCitation, equals('Sal. 55:12-14'));
      expect(spans[1].scripture.book.name, equals('Salmos'));
      expect(spans[1].scripture.chapter, equals(55));
      expect(spans[1].scripture.startVerse, equals(12));
      expect(spans[1].scripture.endVerse, equals(14));
    });

    test('Extracts chained citations inheriting preceding book (2 Sam. 15:13, 14; 18:33 and Sal. 38:5-10; 94:17-19)', () {
      const p12 = 'David sentia um grande peso na consciência por causa de muitos erros que tinha cometido. (Sal. 40:12) Absalão, o seu próprio filho, rebelou-se contra ele e, mais tarde, foi assassinado. (2 Sam. 15:13, 14; 18:33) Além disso, um dos melhores amigos de David acabou por se virar contra ele. (2 Sam. 16:23–17:2; Sal. 55:12-14) Em muitos dos salmos escritos por David, conseguimos perceber que, apesar de ele se sentir desanimado, nada abalava a sua confiança em Jeová. — Sal. 38:5-10; 94:17-19.';

      final spans = BibleCitationParser.extractScriptureSpans(p12);
      expect(spans.length, equals(7));

      expect(spans[0].scripture.rawCitation, equals('Sal. 40:12'));
      expect(spans[0].scripture.book.name, equals('Salmos'));
      expect(spans[0].scripture.chapter, equals(40));
      expect(spans[0].scripture.startVerse, equals(12));

      expect(spans[1].scripture.rawCitation, equals('2 Sam. 15:13, 14'));
      expect(spans[1].scripture.book.name, equals('2 Samuel'));
      expect(spans[1].scripture.chapter, equals(15));
      expect(spans[1].scripture.startVerse, equals(13));
      expect(spans[1].scripture.endVerse, equals(14));

      expect(spans[2].scripture.rawCitation, equals('18:33'));
      expect(spans[2].scripture.book.name, equals('2 Samuel'));
      expect(spans[2].scripture.chapter, equals(18));
      expect(spans[2].scripture.startVerse, equals(33));

      expect(spans[3].scripture.rawCitation, equals('2 Sam. 16:23–17:2'));
      expect(spans[3].scripture.book.name, equals('2 Samuel'));
      expect(spans[3].scripture.chapter, equals(16));
      expect(spans[3].scripture.startVerse, equals(23));

      expect(spans[4].scripture.rawCitation, equals('Sal. 55:12-14'));
      expect(spans[4].scripture.book.name, equals('Salmos'));
      expect(spans[4].scripture.chapter, equals(55));
      expect(spans[4].scripture.startVerse, equals(12));

      expect(spans[5].scripture.rawCitation, equals('Sal. 38:5-10'));
      expect(spans[5].scripture.book.name, equals('Salmos'));
      expect(spans[5].scripture.chapter, equals(38));
      expect(spans[5].scripture.startVerse, equals(5));

      expect(spans[6].scripture.rawCitation, equals('94:17-19'));
      expect(spans[6].scripture.book.name, equals('Salmos'));
      expect(spans[6].scripture.chapter, equals(94));
      expect(spans[6].scripture.startVerse, equals(17));
      expect(spans[6].scripture.endVerse, equals(19));
    });

    test('Parses English citations (Matthew 28:19, 20 and Genesis 1:1)', () {
      final res1 = BibleCitationParser.parse('Matthew 28:19, 20');
      expect(res1, isNotNull);
      expect(res1!.book.id, equals(40));
      expect(res1.chapter, equals(28));
      expect(res1.startVerse, equals(19));
      expect(res1.endVerse, equals(20));

      final res2 = BibleCitationParser.parse('Genesis 1:1');
      expect(res2, isNotNull);
      expect(res2!.book.id, equals(1));
      expect(res2.chapter, equals(1));
      expect(res2.startVerse, equals(1));
    });

    test('Parses Spanish citations (Hechos 2:38 and 1 Juan 4:8)', () {
      final res1 = BibleCitationParser.parse('Hechos 2:38');
      expect(res1, isNotNull);
      expect(res1!.book.id, equals(44));
      expect(res1.chapter, equals(2));
      expect(res1.startVerse, equals(38));

      final res2 = BibleCitationParser.parse('1 Juan 4:8');
      expect(res2, isNotNull);
      expect(res2!.book.id, equals(62));
      expect(res2.chapter, equals(4));
      expect(res2.startVerse, equals(8));
    });

    test('Does not match non-scriptural parenthetical notes', () {
      expect(BibleCitationParser.extractScriptureSpans('(Veja também a nota.)'), isEmpty);
      expect(BibleCitationParser.extractScriptureSpans('(Veja os parágrafos 13 a 15.)*'), isEmpty);
    });

    test('Returns null on non-scriptural text', () {
      expect(BibleCitationParser.parse('Capítulo 5'), isNull);
      expect(BibleCitationParser.parse('Texto comum 123'), isNull);
    });
    test('Parses exact user prompt examples (Rev 21:3, 4, Mat 24:14, 1Co 13:4-8) from jw-core', () {
      final rev = BibleCitationParser.parse('Rev 21:3, 4');
      expect(rev, isNotNull);
      expect(rev!.book.id, equals(66));
      expect(rev.chapter, equals(21));
      expect(rev.startVerse, equals(3));
      expect(rev.endVerse, equals(4));

      final mat = BibleCitationParser.parse('Mat 24:14');
      expect(mat, isNotNull);
      expect(mat!.book.id, equals(40));
      expect(mat.chapter, equals(24));
      expect(mat.startVerse, equals(14));
      expect(mat.endVerse, equals(14));

      final co = BibleCitationParser.parse('1Co 13:4-8');
      expect(co, isNotNull);
      expect(co!.book.id, equals(46));
      expect(co.chapter, equals(13));
      expect(co.startVerse, equals(4));
      expect(co.endVerse, equals(8));

      // Multi-language parity (PT, EN, ES)
      final pt = BibleCitationParser.parse('João 3:16');
      final en = BibleCitationParser.parse('John 3:16');
      final es = BibleCitationParser.parse('Juan 3:16');
      expect(pt!.book.id, equals(43));
      expect(en!.book.id, equals(43));
      expect(es!.book.id, equals(43));
    });
  });
}
