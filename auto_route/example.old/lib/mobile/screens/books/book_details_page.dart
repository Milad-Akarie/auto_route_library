import 'package:auto_route/auto_route.dart';
import 'package:example/data/db.dart';
import 'package:material_ui/material_ui.dart';

@RoutePage(name: 'BookDetailsRoute')
class BookDetailsPage extends StatefulWidget {
  const new({
    super.key,
    @pathParam this.id = -1,
  });
  final int id;

  @override
  BookDetailsPageState createState() => .new();
}

class BookDetailsPageState extends State<BookDetailsPage> {
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
