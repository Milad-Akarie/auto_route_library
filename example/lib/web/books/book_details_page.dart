import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/data/db.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BookDetailsPage extends StatefulWidget {
  final int id;

  const BookDetailsPage({@pathParam this.id});

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
        : Material(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    book.name,
                    style: TextStyle(fontSize: 22),
                  ),
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
                  ),
                ],
              ),
            ),
          );
  }
}
