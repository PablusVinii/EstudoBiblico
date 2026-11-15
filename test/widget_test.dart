import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentinela_study/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SentinelaStudyApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SentinelaStudyApp), findsOneWidget);

    // Verifica abas inferiores da barra de navegação e AppBar
    expect(find.text('A Sentinela'), findsAtLeastNWidgets(1));
    expect(find.text('Bíblia'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
  });
}
