import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentinela_study/services/article_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

  test('ArticleParser parses issue, extracts images, and associates illustrations', () async {
    const epubPath = 'c:/Users/Pablus Vinicius/Downloads/jw/sample_202607.epub';
    if (!File(epubPath).existsSync()) {
      return;
    }

    final parsed = await ArticleParser.parseIssue(epubPath, '202607');
    expect(parsed.articles.isNotEmpty, isTrue);
    expect(parsed.issueCode, equals('202607'));

    final firstArticle = parsed.articles.first;
    expect(firstArticle.paragraphs.isNotEmpty, isTrue);

    final hasIllustration = parsed.articles.any(
      (a) => a.leadImagePath != null || a.paragraphs.any((p) => p.illustrationPath != null),
    );
    expect(hasIllustration, isTrue);
  });

  test('ArticleParser parses legacy (2021 and older) articles without data-pnum', () async {
    const legacyHtml = '''
<html xmlns="http://www.w3.org/1999/xhtml">
<body>
<header>
<p class="contextTtl" id="p1" data-pid="1"><strong>ESTUDO 31</strong></p>
<h1 id="p2" data-pid="2"><strong>“Não desistimos”!</strong></h1>
</header>
<p id="p3" data-pid="3" class="themeScrp">“Por isso não desistimos.” — 2 COR. 4:16.</p>
<p id="p4" data-pid="4" class="pubRefs"><strong>CÂNTICO 128</strong> Persevere até o fim</p>
<div class="bodyTxt">
<div class="pGroup">
<p id="q1" class="qu"> <strong>1. </strong>O que os cristãos precisam fazer para terminar a corrida pela vida?</p>
<p id="p6" data-pid="6" data-rel-pid="[37]" class="p6">OS CRISTÃOS estão em uma corrida pela vida.</p>
<p id="q2" class="qu"> <strong>2. </strong>Por que o conselho de Paulo veio numa boa hora?</p>
<p id="p7" data-pid="7" data-rel-pid="[38]" class="p7"><strong><sup>2 </sup></strong>O conselho de Paulo aos filipenses veio numa boa hora.</p>
</div>
</div>
<aside epub:type="footnote"><div class="extScrpCite"><p>^ parágrafo 17 Fil. 1:9, 10</p></div></aside>
</body>
</html>
''';

    final article = await ArticleParser.parseHtmlArticle(
      '2019520.xhtml',
      legacyHtml,
      {},
      '30 de setembro a 6 de outubro de 2019',
    );

    expect(article, isNotNull);
    expect(article!.title, equals('“Não desistimos”!'));
    expect(article.weekDate, equals('30 de setembro a 6 de outubro de 2019'));
    expect(article.song, contains('CÂNTICO 128'));
    expect(article.paragraphs.length, equals(2));
    expect(article.paragraphs[0].number, equals(1));
    expect(article.paragraphs[0].text, equals('OS CRISTÃOS estão em uma corrida pela vida.'));
    expect(article.paragraphs[0].question, contains('O que os cristãos precisam fazer'));
    expect(article.paragraphs[1].number, equals(2));
    expect(article.paragraphs[1].text, equals('O conselho de Paulo aos filipenses veio numa boa hora.'));
  });

}
