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
      expect(param.converter, null);
    });

    test('named constructor', () {
      const param = PathParam('id');
      expect(param.name, 'id');
      expect(param.converter, null);
    });

    test('inherit constructor', () {
      const param = PathParam.inherit('id');
      expect(param.name, 'id');
      expect(param.converter, null);
    });

    test('constructor with converter', () {
      const param = PathParam('color', _colorConverter);
      expect(param.name, 'color');
      expect(param.converter, same(_colorConverter));
    });

    test('inherit constructor with converter', () {
      const param = PathParam.inherit('color', _colorConverter);
      expect(param.name, 'color');
      expect(param.converter, same(_colorConverter));
    });
  });

  group('QueryParam', () {
    test('default constructor', () {
      const param = QueryParam();
      expect(param.name, null);
      expect(param.converter, null);
    });

    test('named constructor', () {
      const param = QueryParam('foo');
      expect(param.name, 'foo');
      expect(param.converter, null);
    });

    test('constructor with converter', () {
      const param = QueryParam('color', _colorConverter);
      expect(param.name, 'color');
      expect(param.converter, same(_colorConverter));
    });
  });

  group('UrlFragment', () {
    test('constructor', () {
      // Since it's a private constructor, test the exported constant
      expect(urlFragment, isNotNull);
    });
  });
}

enum _Color { red, green, blue }

const _colorConverter = EnumParamConverter<_Color>(_Color.values);
