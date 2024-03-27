import 'package:auto_route/auto_route.dart';
import 'package:example/data/db.dart';
import 'package:flutter/material.dart';

//ignore_for_file: public_member_api_docs
@RoutePage(name: 'BookDetailsRoute')
class BookDetailsPage extends StatefulWidget {
  final int id;

  const BookDetailsPage({
    @pathParam this.id = -3,
  });

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  int counter = 1;

  @override
  Widget build(BuildContext context) {
    final booksDb = BooksDBProvider.of(context);
    final book = booksDb?.findBookById(widget.id);
    return book == null
        ? Container(child: Text('Book null'))
        : Scaffold(
            body: Container(
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
                      ElevatedButton(
                        onPressed: () {
                          context.router.root.maybePop();
                        },
                        child: Text('Pop root'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.router.maybePop();
                        },
                        child: Text('Pop '),
                      ),
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
