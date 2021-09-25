import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../data/db.dart';

class BookDetailsPage extends StatelessWidget {
  final int id;

  const BookDetailsPage({
    @PathParam('id') this.id = -1,
  });

  @override
  Widget build(BuildContext context) {
    final booksDb = BooksDBProvider.of(context);
    var book = booksDb?.findBookById(id);

    return book == null
        ? Container(child: Text('Book null'))
        : _BookDetailsPage(
            book: book,
          );
  }
}

class _BookDetailsPage extends StatefulWidget {
  final Book book;
  const _BookDetailsPage({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  State<_BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<_BookDetailsPage> {
  late int counter;

  @override
  void initState() {
    counter = widget.book.reads;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        child: Hero(
          tag: 'Hero${widget.book.id}',
          child: Card(
            margin: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Book Details/${widget.book.id}'),
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
                      AutoBackButtonState.of(context)?.value =
                          widget.book.copyWith(reads: counter);
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
