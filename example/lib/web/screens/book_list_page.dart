import 'package:example/web/router/router.gr.dart';
import 'package:flutter/material.dart';

import '../web_main.dart';

class BookListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: booksDb.books
            .map((book) => Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(book.name),
                    subtitle: Text(book.genre),
                    onTap: () {
                      BookDetailsPageRoute(id: book.id).push(context);
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }
}
