import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

void main() {
  test('Calling Parameters.get on a any-type value should return a <dynamic>', () {
    const params = Parameters({'key': 'str'});
    expect(params.get('key'), isA<Object?>());
  });

  test('Calling Parameters.getString on a string value should return a <string>', () {
    const params = Parameters({'key': 'str'});
    expect(params.getString('key'), isA<String>());
  });

  test('Calling Parameters.getString on a null value should throw', () {
    const params = Parameters({});
    expect(() => params.getString('key'), throwsFlutterError);
  });

  test('Calling Parameters.optString on a string value should return a <string> and null on a none existing value', () {
    const params = Parameters({'key': 'str'});
    expect(params.optString('key'), isA<String>());
    expect(params.optString('key2'), null);
  });

  test('Calling Parameters.getInt on an int value should return a <int>', () {
    const params = Parameters({'key': '12'});
    expect(params.getInt('key'), isA<int>());
  });

  test('Calling Parameters.getInt on a none-int value should throw', () {
    const params = Parameters({'key': 'str'});
    expect(() => params.getInt('key'), throwsFlutterError);
  });

  test('Calling Parameters.optInt on an int value should return a <int> and null on a none existing value', () {
    const params = Parameters({'key': '12'});
    expect(params.optInt('key'), isA<int>());
    expect(params.optInt('key2'), null);
  });

  test('Calling Parameters.getDouble on an int value should return a <double>', () {
    const params = Parameters({'key': '12'});
    expect(params.getDouble('key'), isA<double>());
  });

  test('Calling Parameters.getDouble on a none-double value should throw', () {
    const params = Parameters({'key': 'str'});
    expect(() => params.getDouble('key'), throwsFlutterError);
  });

  test('Calling Parameters.optDouble on a double value should return a <double> and null on a none existing value', () {
    const params = Parameters({'key': '12.1'});
    expect(params.optDouble('key'), isA<double>());
    expect(params.optDouble('key2'), null);
  });

  test('Calling Parameters.getNum on an int value should return a <int>', () {
    const params = Parameters({'key': '12'});
    expect(params.getNum('key'), isA<int>());
  });

  test('Calling Parameters.getNum on a none-num value should throw', () {
    const params = Parameters({'key': 'str'});
    expect(() => params.getNum('key'), throwsFlutterError);
  });

  test('Calling Parameters.optNum on a double value should return a <num> and null on a none existing value', () {
    const params = Parameters({'key': '12.1'});
    expect(params.optNum('key'), isA<double>());
    expect(params.optNum('key2'), null);
  });

  test('Calling Parameters.getNum on a double value should return a <double>', () {
    const params = Parameters({'key': '12.5'});
    expect(params.getNum('key'), isA<double>());
  });

  test('Calling Parameters.getDouble on a double value should return a <double>', () {
    const params = Parameters({'key': '12.5'});
    expect(params.getDouble('key'), isA<double>());
  });

  test('Calling Parameters.getBool on "true" or "True" string value should return true', () {
    const params = Parameters({'key': 'true', 'key2': 'True'});
    expect(params.getBool('key'), true);
    expect(params.getBool('key2'), true);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1319
  // queryParams: {'key': true} is a bool in the map, not text; getBool and
  // optBool must return it instead of calling toLowerCase on it.
  test('Calling Parameters.getBool and optBool on a bool value should return it', () {
    const params = Parameters({'key': true, 'key2': false});
    expect(params.getBool('key'), true);
    expect(params.getBool('key2'), false);
    expect(params.optBool('key'), true);
  });

  test('Calling Parameters.getBool on a none-bool string-value should throw', () {
    const params = Parameters({'key': 'str'});
    expect(() => params.getBool('key'), throwsFlutterError);
  });

  test(
    'Calling Parameters.optBool on a true-string value should return a <bool> and null on a none existing value',
    () {
      const params = Parameters({'key': 'true'});
      expect(params.optBool('key'), isA<bool>());
      expect(params.optBool('key2'), null);
    },
  );

  test('Calling Parameters.getBool on "false" or "False" string value should return false', () {
    const params = Parameters({'key': 'false', 'key2': 'False'});
    expect(params.getBool('key'), false);
    expect(params.getBool('key2'), false);
  });

  test('Calling Parameters.getList on a list value should return a <List>', () {
    const params = Parameters({
      'key': ['1', '2'],
    });
    expect(params.getList('key'), isA<List<Object?>>());
    expect(params.optList('key2'), null);
  });

  test('Adding two Parameters together should create a new Parameters instance with both keys and values ', () {
    final allParams = const Parameters({'key1': 'value1'}) + const Parameters({'key2': 'value2'});
    expect(allParams.rawMap, {'key1': 'value1', 'key2': 'value2'});
  });

  // https://github.com/Milad-Akarie/auto_route_library/pull/2222
  // Steps: read a bool value, as a route pushed with queryParams {'f': true}
  // holds it, with optBool or getBool.
  // Should: the bool comes back, not NoSuchMethodError on toLowerCase.
  test('Calling Parameters.optBool and getBool on a bool value should return it', () {
    const params = Parameters({'yes': true, 'no': false});
    expect(params.optBool('yes'), true);
    expect(params.optBool('no', true), false);
    expect(params.getBool('yes'), true);
    expect(params.getBool('no'), false);
  });

  test('Calling Parameters.optBool on a string value should read true and false in any case', () {
    const params = Parameters({'a': 'true', 'b': 'FALSE', 'c': 'maybe', 'd': 1});
    expect(params.optBool('a'), true);
    expect(params.optBool('b'), false);
    expect(params.optBool('c'), null);
    expect(params.optBool('c', true), true);
    expect(params.optBool('d'), null);
    expect(params.optBool('missing', false), false);
    expect(() => params.getBool('c'), throwsFlutterError);
  });

  // #1794: a param read by a ParamConverter.
  group('Parameters.optTyped and getTyped (#1794)', () {
    test('read the text by the converter, the last one for a repeated key', () {
      const params = Parameters({
        'id': '7',
        'ids': ['1', '2'],
      });
      expect(params.optTyped('id', const _NumberConverter()), const _Number(7));
      expect(params.getTyped('ids', const _NumberConverter()), const _Number(2));
    });

    test('return a value that already has the type as it is', () {
      const params = Parameters({'id': _Number(5)});
      expect(params.getTyped('id', const _NumberConverter()), const _Number(5));
    });

    test('fall back to the default when the value is missing or the converter refuses it', () {
      const params = Parameters({'id': 'seven'});
      expect(params.optTyped('id', const _NumberConverter()), null);
      expect(params.optTyped('id', const _NumberConverter(), const _Number(1)), const _Number(1));
      expect(params.getTyped('missing', const _NumberConverter(), const _Number(2)), const _Number(2));
    });

    test('getTyped throws naming the key and the text when there is no value', () {
      const params = Parameters({'id': 'seven'});
      expect(
        () => params.getTyped('id', const _NumberConverter()),
        throwsA(
          isA<MissingRequiredParameterError>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to parse [_Number] id value from seven'),
          ),
        ),
      );
    });

    // A converter's own error is the app's bug, so it is not hidden behind
    // the default.
    test("don't catch an error the converter throws", () {
      const params = Parameters({'id': '7'});
      expect(() => params.optTyped('id', const _ThrowingConverter(), const _Number(1)), throwsStateError);
    });
  });
}

@immutable
class _Number {
  const new(this.value);

  final int value;

  @override
  bool operator ==(Object other) => other is _Number && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class _NumberConverter extends ParamConverter<_Number> {
  const new();

  @override
  _Number? fromParam(String value) {
    final number = int.tryParse(value);
    return number == null ? null : _Number(number);
  }

  @override
  String toParam(_Number value) => '${value.value}';
}

class _ThrowingConverter extends ParamConverter<_Number> {
  const new();

  @override
  _Number fromParam(String value) => throw StateError('broken converter');

  @override
  String toParam(_Number value) => '${value.value}';
}
