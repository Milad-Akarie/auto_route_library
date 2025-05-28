/// Recase a string to lowerCamelCase
String toLowerCamelCase(String s) {
  if (s.length < 2) return s.toLowerCase();
  return s[0].toLowerCase() + s.substring(1);
}

/// Capitalize a string
String capitalize(String s) {
  if (s.length < 2) return s.toUpperCase();
  return s[0].toUpperCase() + s.substring(1);
}

/// Recase a string to kabab-case
String toKababCase(String s) {
  return s.replaceAllMapped(RegExp('(.+?)([A-Z])'), (match) => '${match.group(1)}-${match.group(2)}'.toLowerCase());
}

/// Extension methods for [Iterable]
extension IterableExtenstion<E> on Iterable<E> {
  /// Returns the first element that satisfies the given predicate [test]
  /// or `null` if no element satisfies the predicate.
  E? firstWhereOrNull(bool Function(E element) test) {
    for (var e in this) {
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
    for (var e in this) {
      uniqueItems[distinctBy(e)] = e;
    }
    return uniqueItems.values;
  }
}
