/// A book in the example library, identified by an id.
class Book {
  /// All fields are required; [id] must be unique among the books of a
  /// `BooksDB`.
  const new({required this.id, required this.name, required this.genre});

  /// The number routes use to look this book up.
  final int id;

  /// The title shown in the list and on the details page.
  final String name;

  /// The category label, `Fiction` or `Comic` in the sample data.
  final String genre;
}
