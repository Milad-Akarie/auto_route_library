/// Thrown when a route's page needs a parameter it can't get: a required
/// path or query param missing from the url, or one whose text doesn't parse
/// as its type.
///
/// It is bad input, such as a link someone typed, rather than a bug, so it is
/// an [Exception]: catch it with `on MissingRequiredParameterError`.
class MissingRequiredParameterError implements Exception {
  /// Creates the exception; [description] says which parameter and why.
  new(String description)
    : message = 'Missing or invalid required parameter\n$description';

  /// The summary line, then the description given to the constructor.
  final String message;

  @override
  String toString() => message;
}
