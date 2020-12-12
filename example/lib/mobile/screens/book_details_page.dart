import 'package:auto_route/annotations.dart';
import 'package:example/data/books_data.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class BookDetailsPage extends StatefulWidget {
  final int bookId;

  const BookDetailsPage({@PathParam('id') this.bookId});

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  Book book;

  @override
  void initState() {
    super.initState();
    try {
      book = booksDb.findBookById(widget.bookId);
      // ignore: empty_catches
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return book == null
        ? Container(
            child: Text('Book null'),
          )
        : Scaffold(
            appBar: AppBar(title: Text(book.name)),
            body: Center(
              child: Text('Book Details/${book.id}'),
            ),
          );
  }
}
