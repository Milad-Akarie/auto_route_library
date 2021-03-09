bool mapNullOrEmpty(Map? map) {
  return (map == null || map.isEmpty);
}

bool listNullOrEmpty(Iterable? iterable) {
  return (iterable == null || iterable.isEmpty);
}

extension IterableExtenstion<E> on Iterable<E> {
  E? firstOrNull(bool test(E element)) {
    for (var e in this) {
      if (test(e)) {
        return e;
      }
    }
    return null;
  }

  E? lastOrNull(bool test(E element)) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(elementAt(i))) {
        return elementAt(i);
      }
    }
    return null;
  }
}
