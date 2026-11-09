/// Reads from a list without throwing when the element is not there.
///
/// Inside this package these win over the versions of the same name in
/// `dart:core`. A library that also imports `package:collection` hides its
/// `ListExtensions`, or the two would clash.
extension SafeListAccess<E> on List<E> {
  /// The first element, or null when the list is empty.
  E? get firstOrNull => switch (this) {
    [final head, ...] => head,
    _ => null,
  };

  /// The last element, or null when the list is empty.
  E? get lastOrNull => switch (this) {
    [..., final tail] => tail,
    _ => null,
  };

  /// The element at [index], or null when [index] is negative or past the end.
  E? elementAtOrNull(int index) {
    if (index < 0) return null;
    final rest = skip(index).iterator;
    return rest.moveNext() ? rest.current : null;
  }
}
