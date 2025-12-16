import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutoRouterConfig', () {
    test('default constructor', () {
      const config = AutoRouterConfig();
      expect(config.replaceInRouteName, 'Page|Screen,Route');
      expect(config.deferredLoading, false);
      expect(config.generateForDir, const ['lib']);
      expect(config.argsEquality, true);
    });

    test('custom constructor', () {
      const config = AutoRouterConfig(
        replaceInRouteName: 'Page,Route',
        deferredLoading: true,
        generateForDir: ['lib', 'test'],
        argsEquality: false,
      );
      expect(config.replaceInRouteName, 'Page,Route');
      expect(config.deferredLoading, true);
      expect(config.generateForDir, const ['lib', 'test']);
      expect(config.argsEquality, false);
    });
  });

  group('RoutePage', () {
    test('default constructor', () {
      const page = RoutePage();
      expect(page.name, null);
      expect(page.deferredLoading, null);
    });

    test('custom constructor', () {
      const page = RoutePage(name: 'TestRoute', deferredLoading: true);
      expect(page.name, 'TestRoute');
      expect(page.deferredLoading, true);
    });
  });

  group('PathParam', () {
    test('default constructor', () {
      const param = PathParam();
      expect(param.name, null);
    });

    test('named constructor', () {
      const param = PathParam('id');
      expect(param.name, 'id');
    });

    test('inherit constructor', () {
      const param = PathParam.inherit('id');
      expect(param.name, 'id');
    });
  });

  group('QueryParam', () {
    test('default constructor', () {
      const param = QueryParam();
      expect(param.name, null);
    });

    test('named constructor', () {
      const param = QueryParam('foo');
      expect(param.name, 'foo');
    });
  });

  group('UrlFragment', () {
    test('constructor', () {
      // Since it's a private constructor, test the exported constant
      expect(urlFragment, isNotNull);
    });
  });
}
