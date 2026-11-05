import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:example/data/db.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:material_ui/material_ui.dart';

/// Lists all books and opens the details page of the one the user taps.
@RoutePage()
class BookListScreen extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  Future<void> _openDetails(BuildContext context, Book book) async {
    final result = await context.pushRoute<String>(
      BookDetailsRoute(id: book.id),
    );
    debugPrint('BookDetailsRoute result: $result');
  }

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
                onTap: () => unawaited(_openDetails(context, book)),
              ),
            ),
        ],
      ),
    );
  }
}
