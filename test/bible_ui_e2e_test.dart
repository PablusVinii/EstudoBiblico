import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela_study/models/bible_model.dart';
import 'package:sentinela_study/services/bible_service.dart';
import 'package:sentinela_study/screens/bible_languages_dialog.dart';
import 'package:sentinela_study/screens/bible_chapters_screen.dart';
import 'package:sentinela_study/screens/bible_reader_screen.dart';

class FakeBibleService extends BibleService {
  String _active = 'nwt_t';

  @override
  Future<String> getActiveVersionId() async => _active;

  @override
  Future<void> setActiveVersionId(String id) async {
    _active = id;
  }

  @override
  Future<List<BibleVersion>> getVersions() async => BibleService.defaultVersions;

  @override
  Future<BibleVersion> getActiveVersion() async => BibleService.defaultVersions.first;

  @override
  Future<bool> isVersionDownloaded(String versionId) async => false;

  @override
  Future<BibleChapterContent> loadChapter(BibleBook book, int chapter) async {
    return BibleChapterContent(
      bookNumber: book.id,
      bookName: book.name,
      chapterNumber: chapter,
      verses: const [
        BibleVerseItem(verseNumber: 1, text: 'No princípio Deus criou os céus e a terra.'),
        BibleVerseItem(verseNumber: 2, text: 'A terra era vazia e deserta.'),
        BibleVerseItem(verseNumber: 3, text: 'E Deus disse: "Que haja luz." Então houve luz.'),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bible UI Widget & Navigation Tests (Skill e2e-testing)', () {
    testWidgets('BibleLanguagesDialog searches languages and selects active version', (tester) async {
      final fakeService = FakeBibleService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => BibleLanguagesDialog(
                      bibleService: fakeService,
                      onVersionChanged: () {},
                    ),
                  );
                },
                child: const Text('Abrir Idiomas'),
              ),
            ),
          ),
        ),
      );

      // Abre o diálogo
      await tester.tap(find.text('Abrir Idiomas'));
      await tester.pumpAndSettle();

      // Verifica elementos visuais do diálogo de acordo com o design oficial
      expect(find.text('Idiomas'), findsOneWidget);
      expect(find.text('CONCLUÍDO'), findsOneWidget);

      // Testa campo de busca
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'English');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'English'), findsOneWidget);

      // Limpa busca
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Fecha o diálogo com o botão CONCLUÍDO
      await tester.tap(find.text('CONCLUÍDO'));
      await tester.pumpAndSettle();
      expect(find.text('Idiomas'), findsNothing);
    });

    testWidgets('BibleChaptersScreen displays total chapters grid and navigates', (tester) async {
      final fakeService = FakeBibleService();
      final habakkuk = BibleService.books.firstWhere((b) => b.name == 'Habacuque');
      final version = BibleService.defaultVersions.first;

      await tester.pumpWidget(
        MaterialApp(
          home: BibleChaptersScreen(
            book: habakkuk,
            version: version,
            bibleService: fakeService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Habacuque tem 3 capítulos
      expect(find.text('Habacuque'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Introdução a Habacuque'), findsOneWidget);
    });

    testWidgets('BibleReaderScreen renders verse highlights, navigation buttons and study sheet', (tester) async {
      final fakeService = FakeBibleService();
      final genesis = BibleService.books.first;
      final version = BibleService.defaultVersions.first;

      await tester.pumpWidget(
        MaterialApp(
          home: BibleReaderScreen(
            book: genesis,
            initialChapter: 1,
            version: version,
            bibleService: fakeService,
            targetVerse: 3,
            targetEndVerse: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica título e cabeçalho
      expect(find.text('GÊNESIS'), findsOneWidget);
      expect(find.text('Gênesis 1'), findsOneWidget);

      // Verifica renderização dos versículos (RichText)
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('No princípio Deus criou')),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Que haja luz')),
        findsOneWidget,
      );

      // Verifica navegação de capítulos no rodapé
      expect(find.text('Capítulo 2'), findsOneWidget);

      // Testa abertura do Painel de Estudo (FloatingActionButton)
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Painel de Estudo - Gênesis 1'), findsOneWidget);
    });
  });
}
