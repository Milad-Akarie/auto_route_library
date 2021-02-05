import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../data/db.dart';
import '../router/web_router.gr.dart';

class BookListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var booksDb = BooksDBProvider.of(context);
    return Material(
      child: ListView(
        children: booksDb.books
            .map((book) => Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(book.name),
                    subtitle: Text(book.genre),
                    onTap: () {
                      context.router.push(
                        BookDetailsRoute(id: book.id),
                      );
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }
}
