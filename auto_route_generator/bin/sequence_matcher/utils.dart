import 'package:collection/collection.dart';

import 'sequence.dart';
import 'sequence_matcher.dart';

bool hasRouteAnnotation(List<int> byteArray) {
  List<int> targetSequence = [0x40, 0x52, 0x6F, 0x75, 0x74, 0x65]; // ASCII values for '@Route'
  for (int i = 0; i < byteArray.length; i++) {
    if (byteArray[i] == targetSequence[0]) {
      for (int j = 1; j < targetSequence.length; j++) {
        if (byteArray[i + j] != targetSequence[j]) {
          break;
        }
        if (j == targetSequence.length - 1) {
          return true;
        }
      }
    }
  }
  return false;
}

extension MapX<T> on Map<String, Set<T>> {
  /// Appends a value to a set in a map or creates a new set if the key does not exist
  upsert(String key, T value) {
    this[key] = {...?this[key], value};
  }

  /// Appends a list of values to a set in a map or creates a new set if the key does not exist
  upsertAll(String key, Iterable<T> values) {
    this[key] = {...?this[key], ...values};
  }
}

extension IdentifiersMapX on Map<String, ResolvedIdentifiers> {
  /// Appends a value to a set in a map or creates a new set if the key does not exist
  upsert(String key, ResolvedIdentifiers value) {
    this[key] = this[key]?.merge(value) ?? value;
  }
}

extension SequenceListX on Iterable<Sequence> {
  /// Finds the first sequence that matches the given identifier
  Set<String> get uniqueIdentifiers {
    return this.map((e) => e.identifier).toSet();
  }

  Set<String> difference(Set<String> foundUnique) {
    return this.uniqueIdentifiers.difference(foundUnique);
  }

  Iterable<Sequence> notIn(Set<String> foundUnique) {
    return this.whereNot((e) => foundUnique.contains(e.identifier));
  }
}
