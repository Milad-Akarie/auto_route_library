import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:example/data/book.dart';
import 'package:example/data/user.dart';

/// An in-memory set of sample users, each with the books they own.
///
/// Nothing is loaded or saved; the list is fixed in code.
class UsersDB {
  /// The sample users.
  final List<User> users = [
    const User(
      id: 1,
      name: 'User one',
      email: 'userone@email.com',
      books: [
        Book(id: 1, genre: 'Fiction', name: 'Anna Karenina'),
        Book(id: 2, genre: 'Fiction', name: 'The Great Gatsby'),
        Book(id: 3, genre: 'Comic', name: 'Amazing Spider-Man'),
      ],
    ),
    const User(
      id: 2,
      name: 'User two',
      email: 'usertwo@email.com',
      books: [
        Book(id: 5, genre: 'Comic', name: 'The Incredible Hulk'),
        Book(id: 6, genre: 'Fiction', name: 'The Big Sleep'),
        Book(id: 7, genre: 'Fiction', name: 'Woman in White'),
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
