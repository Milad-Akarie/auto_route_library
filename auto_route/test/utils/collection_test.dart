import 'package:auto_route/src/utils/collection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const letters = ['a', 'b', 'c'];
  const nothing = <String>[];

  test('firstOrNull answers the first element, or null when empty', () {
    expect(letters.firstOrNull, 'a');
    expect(nothing.firstOrNull, isNull);
  });

  test('lastOrNull answers the last element, or null when empty', () {
    expect(letters.lastOrNull, 'c');
    expect(nothing.lastOrNull, isNull);
  });

  test('elementAtOrNull answers null outside the list', () {
    expect(letters.elementAtOrNull(0), 'a');
    expect(letters.elementAtOrNull(2), 'c');
    expect(letters.elementAtOrNull(3), isNull);
    expect(letters.elementAtOrNull(-1), isNull);
    expect(nothing.elementAtOrNull(0), isNull);
  });
}
