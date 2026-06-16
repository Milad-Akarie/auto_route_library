import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Color { red, green, blue }

const _colorConverter = EnumParamConverter<_Color>(_Color.values);

class _DateConverter extends ParamConverter<DateTime> {
  const _DateConverter();

  @override
  DateTime fromParam(String? value) => DateTime.parse(value!);

  @override
  String toParam(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

const _dateConverter = _DateConverter();

void main() {
  group('EnumParamConverter', () {
    test('parses by enum name', () {
      expect(_colorConverter.fromParam('red'), _Color.red);
      expect(_colorConverter.fromParam('green'), _Color.green);
      expect(_colorConverter.fromParam('blue'), _Color.blue);
    });

    test('throws StateError on unknown name', () {
      expect(
        () => _colorConverter.fromParam('purple'),
        throwsStateError,
      );
    });

    test('throws StateError on null', () {
      expect(
        () => _colorConverter.fromParam(null),
        throwsStateError,
      );
    });

    test('serializes by enum name', () {
      expect(_colorConverter.toParam(_Color.red), 'red');
      expect(_colorConverter.toParam(_Color.green), 'green');
      expect(_colorConverter.toParam(_Color.blue), 'blue');
    });

    test('round-trips through fromParam/toParam', () {
      for (final c in _Color.values) {
        expect(_colorConverter.fromParam(_colorConverter.toParam(c)), c);
      }
    });
  });

  group('ParamConverter subclass', () {
    test('user-defined converter parses successfully', () {
      expect(
        _dateConverter.fromParam('2026-05-14'),
        DateTime(2026, 5, 14),
      );
    });

    test('user-defined converter rethrows on bad input', () {
      expect(
        () => _dateConverter.fromParam('not-a-date'),
        throwsFormatException,
      );
    });

    test('user-defined converter serializes', () {
      expect(_dateConverter.toParam(DateTime(2026, 5, 14)), '2026-05-14');
    });

    test('round-trips through fromParam/toParam', () {
      final original = DateTime(2026, 5, 14);
      expect(
        _dateConverter.fromParam(_dateConverter.toParam(original)),
        original,
      );
    });
  });

  group('Parameters.optTyped', () {
    test('returns converted value when key is present', () {
      const params = Parameters({'c': 'red'});
      expect(params.optTyped<_Color>('c', _colorConverter), _Color.red);
    });

    test('returns null when key is absent', () {
      const params = Parameters({});
      expect(params.optTyped<_Color>('c', _colorConverter), null);
    });

    test('returns defaultValue when key is absent', () {
      const params = Parameters({});
      expect(
        params.optTyped<_Color>('c', _colorConverter, _Color.blue),
        _Color.blue,
      );
    });

    test(
        'silently returns defaultValue when converter throws '
        '(matches optInt/optDouble fallback)', () {
      const params = Parameters({'c': 'not-a-color'});
      expect(
        params.optTyped<_Color>('c', _colorConverter, _Color.green),
        _Color.green,
      );
    });

    test('silently returns null when converter throws and no default', () {
      const params = Parameters({'c': 'not-a-color'});
      expect(params.optTyped<_Color>('c', _colorConverter), null);
    });
  });

  group('Parameters.getTyped', () {
    test('returns converted value when key is present', () {
      const params = Parameters({'c': 'red'});
      expect(params.getTyped<_Color>('c', _colorConverter), _Color.red);
    });

    test('throws MissingRequiredParameterError when key is absent', () {
      const params = Parameters({});
      expect(
        () => params.getTyped<_Color>('c', _colorConverter),
        throwsFlutterError,
      );
    });

    test('returns defaultValue when key is absent', () {
      const params = Parameters({});
      expect(
        params.getTyped<_Color>('c', _colorConverter, _Color.red),
        _Color.red,
      );
    });

    test('throws when converter fails and no defaultValue is supplied', () {
      const params = Parameters({'c': 'bogus'});
      expect(
        () => params.getTyped<_Color>('c', _colorConverter),
        throwsFlutterError,
      );
    });

    test('returns defaultValue when converter fails', () {
      const params = Parameters({'c': 'bogus'});
      expect(
        params.getTyped<_Color>('c', _colorConverter, _Color.blue),
        _Color.blue,
      );
    });
  });
}
