import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Calling Parameters.get on a any-type value should return a <dynamic>', () {
    const params = Parameters({'key': 'str'});
    expect(params.get('key'), isA<dynamic>());
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

  test('Calling Parameters.getBool on a none-bool string-value should throw', () {
    const params = Parameters({'key': 'str'});
    expect(() => params.getBool('key'), throwsFlutterError);
  });

  test('Calling Parameters.optBool on a true-string value should return a <bool> and null on a none existing value',
      () {
    const params = Parameters({'key': 'true'});
    expect(params.optBool('key'), isA<bool>());
    expect(params.optBool('key2'), null);
  });

  test('Calling Parameters.getBool on "false" or "False" string value should return false', () {
    const params = Parameters({'key': 'false', 'key2': 'False'});
    expect(params.getBool('key'), false);
    expect(params.getBool('key2'), false);
  });

  test('Calling Parameters.getList on a list value should return a <List>', () {
    const params = Parameters({
      'key': ['1', '2']
    });
    expect(params.getList('key'), isA<List>());
    expect(params.optList('key2'), null);
  });

  test('Adding two Parameters together should create a new Parameters instance with both keys and values ', () {
    final allParams = const Parameters({'key1': 'value1'}) + const Parameters({'key2': 'value2'});
    expect(allParams.rawMap, {'key1': 'value1', 'key2': 'value2'});
  });
}
