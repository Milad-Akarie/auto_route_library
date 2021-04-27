// general utils

import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

String toLowerCamelCase(String s) {
  if (s.length < 2) return s.toLowerCase();
  return s[0].toLowerCase() + s.substring(1);
}

String capitalize(String s) {
  if (s.length < 2) return s.toUpperCase();
  return s[0].toUpperCase() + s.substring(1);
}

String toKababCase(String s) {
  return s.replaceAllMapped(RegExp('(.+?)([A-Z])'),
      (match) => '${match.group(1)}-${match.group(2)}'.toLowerCase());
}

void throwIf(bool condition, String message, {Element? element}) {
  if (condition) {
    throwError(message, element: element);
  }
}

void throwError(String message, {Element? element}) {
  throw InvalidGenerationSourceError(
    message,
    element: element,
  );
}

String valueOr(String? value, String or) {
  return value == null || value.isEmpty ? or : value;
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

  Iterable<E> distinctBy<T>(T Function(E e) distinctBy) {
    final uniqueItems = <T, E>{};
    for (var e in this) {
      uniqueItems[distinctBy(e)] = e;
    }
    return uniqueItems.values;
  }
}
