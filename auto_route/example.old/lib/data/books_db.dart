import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:example/data/book.dart';

/// An in-memory set of sample books.
///
/// Nothing is loaded or saved; the list is fixed in code.
class BooksDB {
  /// The sample books, in the order the book list page shows them.
  List<Book> books = const [
    Book(id: 1, genre: 'Fiction', name: 'Anna Karenina'),
    Book(id: 2, genre: 'Fiction', name: 'The Great Gatsby'),
    Book(id: 3, genre: 'Comic', name: 'Amazing Spider-Man'),
    Book(id: 4, genre: 'Comic', name: 'Batman'),
    Book(id: 5, genre: 'Comic', name: 'The Incredible Hulk'),
    Book(id: 6, genre: 'Fiction', name: 'The Big Sleep'),
    Book(id: 7, genre: 'Fiction', name: 'Woman in White'),
  ];

  /// Returns the book whose id is [id].
  ///
  /// Throws a [StateError] when no book has that id.
  Book findBookById(int id) {
    return books.firstWhere(
      (book) => book.id == id,
      orElse: () => throw StateError('Can not find book with id $id'),
    );
  }
}

/// Shares one [BooksDB] with every widget below it.
///
/// Read it with [of]. Dependents are never told to rebuild, because the books
/// never change.
class BooksDBProvider extends InheritedWidget {
  /// Creates a provider that gives its child and the subtree under it a new
  /// [BooksDB].
  new({required super.child, super.key});

  /// The books database this provider shares.
  final booksDb = BooksDB();

  @override
  bool updateShouldNotify(_) {
    return false;
  }

  /// Returns the [BooksDB] of the closest [BooksDBProvider] above [context], or
  /// `null` when there is none.
  static BooksDB? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BooksDBProvider>()
        ?.booksDb;
  }
}
