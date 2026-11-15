import '../models/bible_model.dart';
import 'bible_service.dart';

class ParsedScripture {
  final BibleBook book;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final int? endChapter;
  final String rawCitation;

  const ParsedScripture({
    required this.book,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    this.endChapter,
    required this.rawCitation,
  });

  @override
  String toString() => 'ParsedScripture(${book.name} $chapter:$startVerse-$endVerse)';
}

class ParsedScriptureSpan {
  final int start;
  final int end;
  final ParsedScripture scripture;

  const ParsedScriptureSpan({
    required this.start,
    required this.end,
    required this.scripture,
  });

  @override
  String toString() => '${scripture.rawCitation} [$start-$end]';
}

class BibleCitationParser {
  static final RegExp citationRegex = _buildCitationRegex();
  static final RegExp _chainedRegex = RegExp(
    r'^;\s*(\d+)(?::(\d+)(?:[-–—](\d+):(\d+)|(?:(?:,\s*|[-–—])(\d+))*)?)?(?=[\s)\]”".,;–—]|$)',
    caseSensitive: false,
  );

  static RegExp _buildCitationRegex() {
    final keys = _aliases.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final pattern = keys.map(RegExp.escape).join('|');
    return RegExp(
      r'(?:(?<=[\s(\[“"–—])|^)(' + pattern + r')\.?\s+(\d+)(?::(\d+)(?:[-–—](\d+):(\d+)|(?:(?:,\s*|[-–—])(\d+))*)?)?(?=[\s)\]”".,;–—]|$)',
      caseSensitive: false,
    );
  }

    static const Map<String, int> _aliases = {
    // Book 1
    'genesis': 1, 'génesis': 1, 'gênesis': 1, 'gen': 1, 'gên': 1, 'ge': 1, 'gn': 1, 'gé': 1,
    // Book 2
    'exodus': 2, 'exodo': 2, 'éxodo': 2, 'êxodo': 2, 'exod': 2, 'exo': 2, 'êxo': 2, 'ex': 2, 'éx': 2, 'êx': 2,
    // Book 3
    'leviticus': 3, 'levitico': 3, 'levítico': 3, 'lev': 3, 'le': 3, 'lv': 3,
    // Book 4
    'numbers': 4, 'numeros': 4, 'números': 4, 'num': 4, 'núm': 4, 'nm': 4, 'nu': 4, 'nú': 4,
    // Book 5
    'deuteronomio': 5, 'deuteronômio': 5, 'deuteronomy': 5, 'deut': 5, 'deu': 5, 'de': 5, 'dt': 5,
    // Book 6
    'joshua': 6, 'josue': 6, 'josué': 6, 'josh': 6, 'jos': 6, 'js': 6,
    // Book 7
    'judges': 7, 'jueces': 7, 'juizes': 7, 'juízes': 7, 'judg': 7, 'juiz': 7, 'juíz': 7, 'jue': 7, 'jui': 7, 'juí': 7, 'jc': 7, 'jg': 7, 'jz': 7,
    // Book 8
    'rute': 8, 'ruth': 8, 'rut': 8, 'rt': 8, 'ru': 8,
    // Book 9
    '1 samuel': 9, 'i samuel': 9, '1samuel': 9, '1 sam': 9, 'i sam': 9, '1 sa': 9, '1 sm': 9, '1sam': 9, 'i sa': 9, '1 s': 9, '1sa': 9, '1sm': 9, '1s': 9,
    // Book 10
    'ii samuel': 10, '2 samuel': 10, '2samuel': 10, 'ii sam': 10, '2 sam': 10, 'ii sa': 10, '2 sa': 10, '2 sm': 10, '2sam': 10, '2 s': 10, '2sa': 10, '2sm': 10, '2s': 10,
    // Book 11
    '1 kings': 11, '1 reyes': 11, '1 reis': 11, '1reyes': 11, 'i reis': 11, '1 kgs': 11, '1reis': 11, '1 ki': 11, '1 re': 11, '1 rs': 11, '1kgs': 11, 'i rs': 11, '1 r': 11, '1ki': 11, '1re': 11, '1rs': 11, '1r': 11,
    // Book 12
    '2 kings': 12, '2 reyes': 12, 'ii reis': 12, '2 reis': 12, '2reyes': 12, '2 kgs': 12, '2reis': 12, 'ii rs': 12, '2 ki': 12, '2 re': 12, '2 rs': 12, '2kgs': 12, '2 r': 12, '2ki': 12, '2re': 12, '2rs': 12, '2r': 12,
    // Book 13
    '1 chronicles': 13, '1 cronicas': 13, '1 crónicas': 13, '1 crônicas': 13, 'i cronicas': 13, 'i crônicas': 13, '1cronicas': 13, '1crônicas': 13, '1 chron': 13, '1 cron': 13, '1 crôn': 13, '1 chr': 13, '1 crô': 13, '1cron': 13, '1crôn': 13, '1 cr': 13, '1chr': 13, '1cro': 13, '1crô': 13, '1ch': 13, '1cr': 13,
    // Book 14
    '2 chronicles': 14, 'ii cronicas': 14, 'ii crônicas': 14, '2 cronicas': 14, '2 crónicas': 14, '2 crônicas': 14, '2cronicas': 14, '2crônicas': 14, '2 chron': 14, '2 cron': 14, '2 crôn': 14, '2 chr': 14, '2 crô': 14, '2cron': 14, '2crôn': 14, '2 cr': 14, '2chr': 14, '2cro': 14, '2crô': 14, '2ch': 14, '2cr': 14,
    // Book 15
    'esdras': 15, 'ezra': 15, 'esd': 15, 'ezr': 15, 'ed': 15,
    // Book 16
    'nehemiah': 16, 'nehemías': 16, 'neemias': 16, 'neem': 16, 'nee': 16, 'neh': 16, 'ne': 16,
    // Book 17
    'esther': 17, 'ester': 17, 'esth': 17, 'est': 17, 'es': 17, 'et': 17,
    // Book 18
    'job': 18, 'jó': 18,
    // Book 19
    'psalms': 19, 'salmos': 19, 'psalm': 19, 'salmo': 19, 'salm': 19, 'psa': 19, 'pss': 19, 'sal': 19, 'ps': 19, 'sl': 19,
    // Book 20
    'proverbios': 20, 'provérbios': 20, 'proverbio': 20, 'provérbio': 20, 'proverbs': 20, 'prov': 20, 'pro': 20, 'pr': 20, 'pv': 20,
    // Book 21
    'ecclesiastes': 21, 'eclesiastes': 21, 'eclesiastés': 21, 'eccl': 21, 'ecl': 21, 'ec': 21,
    // Book 22
    'cantar de los cantares': 22, 'cantico de salomao': 22, 'cântico de salomão': 22, 'song of solomon': 22, 'cantares': 22, 'canticos': 22, 'cânticos': 22, 'cântico': 22, 'cant': 22, 'song': 22, 'can': 22, 'cnt': 22, 'cân': 22, 'ca': 22, 'ct': 22, 'ss': 22,
    // Book 23
    'isaiah': 23, 'isaias': 23, 'isaías': 23, 'isa': 23, 'is': 23,
    // Book 24
    'jeremiah': 24, 'jeremias': 24, 'jeremías': 24, 'jer': 24, 'je': 24, 'jr': 24,
    // Book 25
    'lamentaciones': 25, 'lamentations': 25, 'lamentacoes': 25, 'lamentações': 25, 'lam': 25, 'la': 25, 'lm': 25,
    // Book 26
    'ezequiel': 26, 'ezekiel': 26, 'ezek': 26, 'eze': 26, 'ez': 26,
    // Book 27
    'daniel': 27, 'dan': 27, 'da': 27, 'dn': 27,
    // Book 28
    'oseias': 28, 'oséias': 28, 'hosea': 28, 'oseas': 28, 'hos': 28, 'ose': 28, 'osé': 28, 'ho': 28, 'os': 28,
    // Book 29
    'joel': 29, 'joe': 29, 'jl': 29,
    // Book 30
    'amos': 30, 'amós': 30, 'amo': 30, 'amó': 30, 'am': 30,
    // Book 31
    'obadiah': 31, 'obadias': 31, 'abdias': 31, 'abdías': 31, 'obad': 31, 'oba': 31, 'ab': 31, 'ob': 31,
    // Book 32
    'jonah': 32, 'jonas': 32, 'jonás': 32, 'jon': 32,
    // Book 33
    'miqueias': 33, 'miquéias': 33, 'miqueas': 33, 'micah': 33, 'mic': 33, 'miq': 33, 'mi': 33, 'mq': 33,
    // Book 34
    'nahum': 34, 'nahúm': 34, 'naum': 34, 'nah': 34, 'nau': 34, 'na': 34,
    // Book 35
    'habacuque': 35, 'habakkuk': 35, 'habacuc': 35, 'hab': 35, 'hc': 35,
    // Book 36
    'zephaniah': 36, 'sofonias': 36, 'sofonías': 36, 'zeph': 36, 'sof': 36, 'zep': 36, 'sf': 36,
    // Book 37
    'haggai': 37, 'hageo': 37, 'ageu': 37, 'age': 37, 'hag': 37, 'ag': 37,
    // Book 38
    'zechariah': 38, 'zacarias': 38, 'zacarías': 38, 'zech': 38, 'zac': 38, 'zec': 38, 'za': 38, 'zc': 38,
    // Book 39
    'malaquias': 39, 'malaquías': 39, 'malachi': 39, 'mal': 39, 'ml': 39,
    // Book 40
    'matthew': 40, 'mateus': 40, 'mateo': 40, 'matt': 40, 'mat': 40, 'mt': 40,
    // Book 41
    'marcos': 41, 'mark': 41, 'mar': 41, 'mc': 41, 'mk': 41, 'mr': 41,
    // Book 42
    'lucas': 42, 'luke': 42, 'luc': 42, 'lc': 42, 'lk': 42, 'lu': 42,
    // Book 43
    'joao': 43, 'john': 43, 'joão': 43, 'juan': 43, 'joh': 43, 'joã': 43, 'jua': 43, 'jn': 43, 'jo': 43,
    // Book 44
    'atos dos apostolos': 44, 'atos dos apóstolos': 44, 'hechos': 44, 'acts': 44, 'atos': 44, 'act': 44, 'hch': 44, 'ac': 44, 'at': 44,
    // Book 45
    'romanos': 45, 'romans': 45, 'rom': 45, 'rm': 45, 'ro': 45,
    // Book 46
    '1 corinthians': 46, '1 corintios': 46, '1 coríntios': 46, 'i coríntios': 46, '1corintios': 46, '1coríntios': 46, '1 cor': 46, 'i cor': 46, '1 co': 46, '1cor': 46, '1co': 46,
    // Book 47
    '2 corinthians': 47, 'ii coríntios': 47, '2 corintios': 47, '2 coríntios': 47, '2corintios': 47, '2coríntios': 47, 'ii cor': 47, '2 cor': 47, '2 co': 47, '2cor': 47, '2co': 47,
    // Book 48
    'galatians': 48, 'galatas': 48, 'gálatas': 48, 'gal': 48, 'gál': 48, 'ga': 48, 'gl': 48,
    // Book 49
    'ephesians': 49, 'efesios': 49, 'efésios': 49, 'efe': 49, 'efé': 49, 'eph': 49, 'ef': 49, 'ep': 49,
    // Book 50
    'philippians': 50, 'filipenses': 50, 'filip': 50, 'phil': 50, 'fil': 50, 'flp': 50, 'php': 50, 'fp': 50,
    // Book 51
    'colossenses': 51, 'colosenses': 51, 'colossians': 51, 'colos': 51, 'col': 51, 'cl': 51,
    // Book 52
    '1 tessalonicenses': 52, '1 tesalonicenses': 52, '1tessalonicenses': 52, '1 thessalonians': 52, '1 thess': 52, '1 tess': 52, 'i tess': 52, '1 tes': 52, '1tess': 52, '1thes': 52, 'i tes': 52, '1 te': 52, '1 ts': 52, '1tes': 52, '1te': 52, '1th': 52, '1ts': 52,
    // Book 53
    '2 tessalonicenses': 53, '2 tesalonicenses': 53, '2tessalonicenses': 53, '2 thessalonians': 53, '2 thess': 53, 'ii tess': 53, '2 tess': 53, 'ii tes': 53, '2 tes': 53, '2tess': 53, '2thes': 53, '2 te': 53, '2 ts': 53, '2tes': 53, '2te': 53, '2th': 53, '2ts': 53,
    // Book 54
    '1 timoteo': 54, '1 timothy': 54, '1 timóteo': 54, '1timoteo': 54, '1timóteo': 54, '1 tim': 54, 'i tim': 54, '1 ti': 54, '1 tm': 54, '1tim': 54, 'i ti': 54, '1ti': 54, '1tm': 54,
    // Book 55
    '2 timoteo': 55, '2 timothy': 55, '2 timóteo': 55, '2timoteo': 55, '2timóteo': 55, 'ii tim': 55, '2 tim': 55, 'ii ti': 55, '2 ti': 55, '2 tm': 55, '2tim': 55, '2ti': 55, '2tm': 55,
    // Book 56
    'titus': 56, 'tito': 56, 'tit': 56, 'tt': 56,
    // Book 57
    'philemon': 57, 'filemon': 57, 'filemón': 57, 'filêmon': 57, 'philem': 57, 'filem': 57, 'filêm': 57, 'phlm': 57, 'flm': 57, 'phm': 57, 'fm': 57,
    // Book 58
    'hebreos': 58, 'hebreus': 58, 'hebrews': 58, 'hebreu': 58, 'heb': 58, 'hb': 58,
    // Book 59
    'santiago': 59, 'james': 59, 'tiago': 59, 'jam': 59, 'jas': 59, 'snt': 59, 'stg': 59, 'tia': 59, 'tg': 59,
    // Book 60
    '1 pedro': 60, '1 peter': 60, 'i pedro': 60, '1pedro': 60, '1 ped': 60, '1 pet': 60, 'i ped': 60, '1 pe': 60, '1ped': 60, '1pet': 60, 'i pe': 60, '1pd': 60, '1pe': 60,
    // Book 61
    'ii pedro': 61, '2 pedro': 61, '2 peter': 61, '2pedro': 61, 'ii ped': 61, '2 ped': 61, '2 pet': 61, 'ii pe': 61, '2 pe': 61, '2ped': 61, '2pet': 61, '2pd': 61, '2pe': 61,
    // Book 62
    '1 joao': 62, '1 john': 62, '1 joão': 62, '1 juan': 62, 'i joão': 62, '1 joh': 62, '1 joã': 62, '1joao': 62, '1joão': 62, '1 jn': 62, '1 jo': 62, '1jua': 62, 'i jo': 62, '1jn': 62, '1jo': 62,
    // Book 63
    'ii joão': 63, '2 joao': 63, '2 john': 63, '2 joão': 63, '2 juan': 63, '2 joh': 63, '2 joã': 63, '2joao': 63, '2joão': 63, 'ii jo': 63, '2 jn': 63, '2 jo': 63, '2jua': 63, '2jn': 63, '2jo': 63,
    // Book 64
    'iii joão': 64, '3 joao': 64, '3 john': 64, '3 joão': 64, '3 juan': 64, 'iii jo': 64, '3 joh': 64, '3 joã': 64, '3joao': 64, '3joão': 64, '3 jn': 64, '3 jo': 64, '3jua': 64, '3jn': 64, '3jo': 64,
    // Book 65
    'judas': 65, 'jude': 65, 'jud': 65, 'jd': 65,
    // Book 66
    'apocalipsis': 66, 'apocalipse': 66, 'revelation': 66, 'revelacao': 66, 'revelação': 66, 'apoc': 66, 'apo': 66, 'rev': 66, 'ap': 66, 're': 66,
  };

  static ParsedScripture _buildScripture(
    BibleBook book,
    int num1,
    int? num2,
    int? crossChap,
    int? crossVerse,
    int? numLast,
    String raw,
  ) {
    int chapter = 1;
    int startVerse = 1;
    int endVerse = 1;
    int? endChapter;

    if (num2 != null) {
      chapter = num1.clamp(1, book.totalChapters);
      startVerse = num2;
      if (crossChap != null && crossVerse != null) {
        endChapter = crossChap.clamp(1, book.totalChapters);
        endVerse = crossVerse;
      } else if (numLast != null) {
        endVerse = numLast;
      } else {
        endVerse = num2;
      }
    } else {
      if (book.totalChapters == 1) {
        chapter = 1;
        startVerse = num1;
        endVerse = num1;
      } else {
        chapter = num1.clamp(1, book.totalChapters);
        startVerse = 1;
        endVerse = 1;
      }
    }

    return ParsedScripture(
      book: book,
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
      endChapter: endChapter,
      rawCitation: raw,
    );
  }

  /// Extrai todas as referências bíblicas encontradas em um bloco de texto,
  /// incluindo citações encadeadas (; 18:33; 94:17-19) e intervalos entre capítulos.
  static List<ParsedScriptureSpan> extractScriptureSpans(String text) {
    final spans = <ParsedScriptureSpan>[];
    int cursor = 0;

    for (final m in citationRegex.allMatches(text)) {
      if (m.start < cursor) continue;

      final bookRaw = (m.group(1) ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      final bookId = _aliases[bookRaw];
      if (bookId == null || bookId < 1 || bookId > BibleService.books.length) {
        continue;
      }
      final book = BibleService.books[bookId - 1];

      final num1 = int.tryParse(m.group(2) ?? '') ?? 1;
      final num2 = int.tryParse(m.group(3) ?? '');
      final crossChap = int.tryParse(m.group(4) ?? '');
      final crossVerse = int.tryParse(m.group(5) ?? '');
      final numLast = int.tryParse(m.group(6) ?? '');

      final rawMatched = text.substring(m.start, m.end);
      final scripture = _buildScripture(book, num1, num2, crossChap, crossVerse, numLast, rawMatched);

      spans.add(ParsedScriptureSpan(start: m.start, end: m.end, scripture: scripture));
      cursor = m.end;

      // Segue citações encadeadas que herdam o mesmo livro (ex: "; 18:33" ou "; 94:17-19")
      while (cursor < text.length) {
        final remaining = text.substring(cursor);
        final cm = _chainedRegex.firstMatch(remaining);
        if (cm != null) {
          final cNum1 = int.tryParse(cm.group(1) ?? '');
          if (cNum1 == null || cNum1 > book.totalChapters) {
            break;
          }
          final cNum2 = int.tryParse(cm.group(2) ?? '');
          final cCrossChap = int.tryParse(cm.group(3) ?? '');
          final cCrossVerse = int.tryParse(cm.group(4) ?? '');
          final cNumLast = int.tryParse(cm.group(5) ?? '');

          final fullMatch = cm.group(0)!;
          final digitIdx = fullMatch.indexOf(RegExp(r'\d'));
          final spanStart = cursor + digitIdx;
          final spanEnd = cursor + fullMatch.length;
          final spanRaw = text.substring(spanStart, spanEnd);

          final chainedScripture = _buildScripture(book, cNum1, cNum2, cCrossChap, cCrossVerse, cNumLast, spanRaw);
          spans.add(ParsedScriptureSpan(start: spanStart, end: spanEnd, scripture: chainedScripture));
          cursor = spanEnd;
        } else {
          break;
        }
      }
    }

    return spans;
  }

  static ParsedScripture? parse(String text) {
    final spans = extractScriptureSpans(text.trim());
    if (spans.isNotEmpty) {
      return spans.first.scripture;
    }
    return null;
  }
}

