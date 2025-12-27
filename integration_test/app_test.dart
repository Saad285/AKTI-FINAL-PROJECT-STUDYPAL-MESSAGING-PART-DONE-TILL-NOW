import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gcr/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App starts and shows home screen', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.text('My Dashboard'), findsOneWidget);
  });
}
