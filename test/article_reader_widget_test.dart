import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentinela_study/models/article.dart';
import 'package:sentinela_study/screens/article_reader_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ArticleReaderScreen renders paragraphs and handles dual comments', (tester) async {
    final article = StudyArticle(
      id: 'test_art_1',
      title: 'O que aprendemos com os gibeonitas?',
      themeScripture: 'Josué 9:14',
      weekDate: '7-13 de setembro de 2026',
      paragraphs: [
        StudyParagraph(
          number: 1,
          text: 'Os gibeonitas agiram com sabedoria quando souberam das vitórias de Israel.',
          questionNumber: '1',
          question: 'Como os gibeonitas agiram com sabedoria?',
          directComment: 'Eles reconheceram o poder de Jeová e buscaram fazer a paz.',
          additionalComment: 'Josué 9 mostra que a humildade deles os salvou da destruição.',
        ),
      ],
      reviewQuestions: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ArticleReaderScreen(article: article),
      ),
    );
    await tester.pumpAndSettle();

    // Verifica se o texto do parágrafo e a pergunta estão na tela
    expect(find.text('Como os gibeonitas agiram com sabedoria?'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Text && w.textSpan?.toPlainText().contains('Os gibeonitas agiram') == true),
      findsOneWidget,
    );

    // Verifica se os chips do jw-meeting-prep estão presentes
    expect(find.text('Direto (1-2 frases)'), findsOneWidget);
    expect(find.text('Aprofundado / Aplicação'), findsOneWidget);

    // Toca no chip "Direto"
    await tester.tap(find.text('Direto (1-2 frases)'));
    await tester.pumpAndSettle();

    // Verifica se o texto do TextField foi preenchido com o comentário direto
    expect(find.text('Eles reconheceram o poder de Jeová e buscaram fazer a paz.'), findsOneWidget);

    // Toca no chip "Aprofundado"
    await tester.tap(find.text('Aprofundado / Aplicação'));
    await tester.pumpAndSettle();

    // Verifica se o texto do TextField foi atualizado para o comentário aprofundado
    expect(find.text('Josué 9 mostra que a humildade deles os salvou da destruição.'), findsOneWidget);
  });
}
