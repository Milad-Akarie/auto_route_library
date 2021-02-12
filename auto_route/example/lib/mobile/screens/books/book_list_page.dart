import 'package:flutter/material.dart';

import '../../../data/db.dart';
import '../../router/router.gr.dart';

class BookListPage extends StatelessWidget {
  BookListPage(final String id);
  @override
  Widget build(BuildContext context) {
    var booksDb = BooksDBProvider.of(context);
    return ListView(
      children: booksDb.books
          .map((book) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(book.name),
                  subtitle: Text(book.genre),
                  onTap: () {
                    // context.router.push(BookDetailsRoute(id: book.id));
                    BookDetailsRoute(id: book.id, pages: ['1', '2']).show(context);
                  },
                ),
              ))
          .toList(),
    );
  }
}
