import 'package:auto_route/auto_route.dart';
import 'package:example/data/db.dart';
import 'package:flutter/material.dart';

//ignore_for_file: public_member_api_docs
@RoutePage(name: 'BookDetailsRoute')
class BookDetailsPage extends StatefulWidget {
  final int id;

  const BookDetailsPage({
    super.key,
    @pathParam this.id = -1,
  });

  @override
  BookDetailsPageState createState() => BookDetailsPageState();
}

class BookDetailsPageState extends State<BookDetailsPage> {
  int counter = 1;

  @override
  Widget build(BuildContext context) {
    final booksDb = BooksDBProvider.of(context);
    final book = booksDb?.findBookById(widget.id);
    return book == null
        ? Text('Book null')
        : Scaffold(
            body: SizedBox(
              width: double.infinity,
              child: Hero(
                tag: 'Hero${book.id}',
                child: Card(
                  margin: const EdgeInsets.all(48),
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
                        heroTag: null,
                        onPressed: () {
                          setState(() {
                            counter++;
                          });
                        },
                        child: Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
