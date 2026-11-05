import 'package:cupertino_ui/cupertino_ui.dart';

/// A book in the example library, identified by an id.
class Book {
  /// All fields are required; [id] must be unique among the books of a
  /// [BooksDB].
  const new({required this.id, required this.name, required this.genre});

  /// The number routes use to look this book up.
  final int id;

  /// The title shown in the list and on the details page.
  final String name;

  /// The category label, `Fiction` or `Comic` in the sample data.
  final String genre;
}

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

/// An in-memory set of sample users, each with the books they own.
///
/// Nothing is loaded or saved; the list is fixed in code.
class UsersDB {
  /// The sample users.
  final List<User> users = [
    User(
      id: 1,
      name: 'User one',
      email: 'userone@email.com',
      books: [
        const Book(id: 1, genre: 'Fiction', name: 'Anna Karenina'),
        const Book(id: 2, genre: 'Fiction', name: 'The Great Gatsby'),
        const Book(id: 3, genre: 'Comic', name: 'Amazing Spider-Man'),
      ],
    ),
    User(
      id: 2,
      name: 'User two',
      email: 'usertwo@email.com',
      books: [
        const Book(id: 5, genre: 'Comic', name: 'The Incredible Hulk'),
        const Book(id: 6, genre: 'Fiction', name: 'The Big Sleep'),
        const Book(id: 7, genre: 'Fiction', name: 'Woman in White'),
      ],
    ),
  ];

  /// Returns the user whose id is [id].
  ///
  /// Throws a [StateError] when no user has that id.
  User findUserById(int id) {
    return users.firstWhere(
      (user) => user.id == id,
      orElse: () => throw StateError('Can not find user with id $id'),
    );
  }
}

/// A person in the example app, with the books they own.
class User {
  /// All fields are required; [id] must be unique among the users of a
  /// [UsersDB].
  new({
    required this.id,
    required this.name,
    required this.email,
    required this.books,
  });

  /// The number used to look this user up.
  final int id;

  /// The display name of this user.
  final String name;

  /// The contact address of this user; a made-up value in the sample data.
  final String email;

  /// The books this user owns.
  final List<Book> books;
}

/// Shares one [UsersDB] with every widget below it.
///
/// Read it with [of]. Dependents are never told to rebuild, because the users
/// never change.
class UsersDBProvider extends InheritedWidget {
  /// Creates a provider that gives its child and the subtree under it a new
  /// [UsersDB].
  new({required super.child, super.key});

  /// The users database this provider shares.
  final usersDB = UsersDB();

  @override
  bool updateShouldNotify(_) {
    return false;
  }

  /// Returns the [UsersDB] of the closest [UsersDBProvider] above [context], or
  /// `null` when there is none.
  static UsersDB? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<UsersDBProvider>()
        ?.usersDB;
  }
}
