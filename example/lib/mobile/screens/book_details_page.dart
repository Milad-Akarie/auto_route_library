import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/data/books_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BookDetailsPage extends StatefulWidget {
  final int id;
  final String queryFilter;

  //
  const BookDetailsPage({
    @PathParam('id') @required this.id,
    @queryParam this.queryFilter,
  });

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  @override
  Widget build(BuildContext context) {
    print(context.route.queryParams);
    context.router.parent().root;
    final booksDb = Provider.of<BooksDB>(context);
    final book = booksDb.findBookById(widget.id);
    return book == null
        ? Container(child: Text('Book null'))
        : Scaffold(
            appBar: AppBar(
              title: Text(book.name),
            ),
            body: Center(
              child: Text('Book Details/${book.id}'),
            ),
          );
  }
}
