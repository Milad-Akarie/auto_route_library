import 'package:flutter_test/flutter_test.dart';

import 'main_router.dart';
import 'test_page.dart';

void main() {
  group('generated routes serialize typed params via ParamConverter.toParam', () {
    test('enum path param stringifies by name', () {
      final route = EnumPathRoute(color: TestColor.green);
      expect(route.rawPathParams['color'], 'green');
    });

    test('enum query param stringifies by name', () {
      final route = EnumQueryRoute(color: TestColor.blue);
      expect(route.rawQueryParams['color'], 'blue');
    });

    test('null enum query param stays null', () {
      final route = EnumQueryRoute(color: null);
      expect(route.rawQueryParams['color'], null);
    });

    test('custom type uses user-defined toParam', () {
      final route = DateRoute(date: const TestDate(2026, 5, 14));
      expect(route.rawQueryParams['date'], '2026-5-14');
    });

    test('null custom type stays null', () {
      final route = DateRoute(date: null);
      expect(route.rawQueryParams['date'], null);
    });
  });
}
