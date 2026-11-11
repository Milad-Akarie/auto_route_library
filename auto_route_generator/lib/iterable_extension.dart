/// Extension methods for [Iterable]
extension IterableExtension<E> on Iterable<E> {
  /// Returns the first element that satisfies the given predicate [test]
  /// or `null` if no element satisfies the predicate.
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final e in this) {
      if (test(e)) {
        return e;
      }
    }
    return null;
  }

  /// Returns the last element that satisfies the given predicate [test]
  /// or `null` if no element satisfies the predicate.
  E? lastOrNull(bool Function(E element) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(elementAt(i))) {
        return elementAt(i);
      }
    }
    return null;
  }

  /// Returns a distinct list of elements by the given [distinctBy] function
  Iterable<E> distinctBy<T>(T Function(E e) distinctBy) {
    final uniqueItems = <T, E>{};
    for (final e in this) {
      uniqueItems[distinctBy(e)] = e;
    }
    return uniqueItems.values;
  }
}
