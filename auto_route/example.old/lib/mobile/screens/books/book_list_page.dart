import 'package:auto_route/auto_route.dart';
import 'package:example/data/db.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:material_ui/material_ui.dart';

/// Lists all books and opens the details page of the one the user taps.
@RoutePage()
// An example page, kept as written so the example shows the same code.
// ignore: avoid-unnecessary-stateful-widgets
class BookListScreen extends StatefulWidget {
  /// Creates the page.
  const new({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  @override
  Widget build(BuildContext context) {
    final booksDb = BooksDBProvider.of(context);
    return Scaffold(
      body: ListView(
        children: [
          for (final book in booksDb?.books ?? const <Book>[])
            Card(
              margin: const .symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(book.name),
                subtitle: Text(book.genre),
                onTap: () async {
                  final result = await context.pushRoute<String>(
                    BookDetailsRoute(id: book.id),
                  );
                  debugPrint('BookDetailsRoute result: $result');
                },
              ),
            ),
        ],
      ),
    );
  }
}
