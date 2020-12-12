import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/data/books_data.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BookDetailsPage extends StatefulWidget {
  final int bookId;

  const BookDetailsPage({@PathParam('id') this.bookId});

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final booksDb = Provider.of<BooksDB>(context);
    final book = booksDb.findBookById(widget.bookId);
    return book == null
        ? Container(child: Text('Book null'))
        : Scaffold(
            appBar: AppBar(
              title: Text(book.name),
              actions: [
                FlatButton(
                    child: Text('Remove list'),
                    onPressed: () {
                      context.router.removeWhere((route) => route.key == BookListPageRoute.key);
                    })
              ],
            ),
            body: Center(
              child: Text('Book Details/${book.id}'),
            ),
          );
  }
}
