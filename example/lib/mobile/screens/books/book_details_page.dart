import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/data/books_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BookDetailsPage extends StatefulWidget {
  final int id;
  final String queryFilter;

  const BookDetailsPage({
    @PathParam('id') this.id = 1,
    @queryParam this.queryFilter,
  });

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Book Details/${book.id}'),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      'Reads  $counter',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FloatingActionButton(
                    child: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        counter++;
                      });
                    },
                  )
                ],
              ),
            ),
          );
  }
}
