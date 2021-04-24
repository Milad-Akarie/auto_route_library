import 'package:flutter/material.dart';

import '../../../data/db.dart';
import '../../router/router.gr.dart';
import 'package:auto_route/auto_route.dart';

class BookListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var booksDb = BooksDBProvider.of(context);
    return ListView(
      children: booksDb?.books
              .map((book) => Column(
                    children: [
                      Hero(
                        tag: 'Hero${book.id}',
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(book.name),
                            subtitle: Text(book.genre),
                            onTap: () {
                              // BookDetailsRoute(id: book.id).show(context);
                              MyBooksRoute().show(context);
                            },
                          ),
                        ),
                      ),
                    ],
                  ))
              .toList() ??
          const [],
    );
  }
}
