import 'package:example/mobile/main.dart';
import 'package:example/mobile/screens/books/book_list_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('The example app starts on the book list', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(BookListScreen), findsOneWidget);
  });
}
