import 'package:auto_route/auto_route.dart';
import 'package:example/data/books_db.dart';
import 'package:material_ui/material_ui.dart';

/// Shows one book, with a counter of reads that the user raises with a button.
@RoutePage(name: 'BookDetailsRoute')
class BookDetailsPage extends StatefulWidget {
  /// Takes the book [id], which defaults to -1 and so finds no book.
  const new({super.key, @pathParam this.id = -1});

  /// The id of the book to show, read from the path.
  final int id;

  @override
  BookDetailsPageState createState() => .new();
}

/// State of [BookDetailsPage]; holds the counter of reads.
class BookDetailsPageState extends State<BookDetailsPage> {
  /// How many reads are shown; starts at 1 and is raised by the button.
  int counter = 1;

  @override
  Widget build(BuildContext context) {
    final booksDb = BooksDBProvider.of(context);
    final book = booksDb?.findBookById(widget.id);
    return book == null
        ? const Text('Book null')
        : Scaffold(
            body: SizedBox(
              width: .infinity,
              child: Hero(
                tag: 'Hero${book.id}',
                child: Card(
                  margin: const .all(48),
                  child: Column(
                    mainAxisAlignment: .center,
                    children: [
                      Text('Book Details/${book.id}'),
                      Padding(
                        padding: const .only(top: 24),
                        child: Text(
                          'Reads  $counter',
                          style: const TextStyle(fontSize: 20),
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
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
