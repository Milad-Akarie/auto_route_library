import 'package:auto_route/auto_route.dart';
import 'package:example/data/db.dart';
import 'package:example/web/router/web_router.gr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BookListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var booksDb = Provider.of<BooksDB>(context);
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
