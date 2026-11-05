import 'package:example/data/book.dart';

/// A person in the example app, with the books they own.
class User {
  /// All fields are required; [id] must be unique among the users of a
  /// `UsersDB`.
  const new({
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
