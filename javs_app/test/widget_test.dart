import 'package:flutter_test/flutter_test.dart';
import 'package:javs_app/main.dart';

void main() {
  testWidgets('Carga la pantalla inicial de Jabs Quizz!', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const JabsQuizzApp());

    expect(find.text('Jabs Quizz!'), findsOneWidget);
    expect(find.text('¡ENTRAR!'), findsOneWidget);
  });
}
