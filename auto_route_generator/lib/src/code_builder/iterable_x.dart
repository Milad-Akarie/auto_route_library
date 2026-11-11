/// Helpers for building code from several parts.
extension IterableX<T> on Iterable<T> {
  /// The elements of this iterable with [element] between each pair.
  Iterable<T> insertBetween(T element) sync* {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      yield iterator.current;
      while (iterator.moveNext()) {
        yield element;
        yield iterator.current;
      }
    }
  }
}
