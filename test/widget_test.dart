import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela_study/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SentinelaStudyApp());
    expect(find.byType(SentinelaStudyApp), findsOneWidget);
  });
}
