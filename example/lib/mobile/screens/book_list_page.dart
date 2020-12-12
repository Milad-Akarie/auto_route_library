import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class BookListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book List')),
      body: ListView(
        children: booksDb.books
            .map((book) => Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(book.name),
                    subtitle: Text(book.genre),
                    onTap: () {
                      BookDetails(id: book.id).push(context);
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }
}
