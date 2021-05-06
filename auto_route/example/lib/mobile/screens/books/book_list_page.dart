import 'package:flutter/material.dart';

import '../../../data/db.dart';
import '../../router/router.gr.dart';

class BookListPage extends StatefulWidget {
  @override
  _BookListPageState createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> with RouteAware {
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
                              BookDetailsRoute(id: book.id).show(context);
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

  @override
  void didPopNext() {
    print('Route aware did pop next ----->');
    super.didPopNext();
  }

  @override
  void didPush() {
    print('Route aware did push ----->');
    super.didPush();
  }
}
