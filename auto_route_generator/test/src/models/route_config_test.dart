import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:test/test.dart';

extension on String {
  String get cap {
    if (length < 2) return toUpperCase();
    return this[0].toUpperCase() + substring(1);
  }
}

void main() {
  group('RouteConfig', () {
    group('defaultRouteName()', () {
      test(
        'returns valid default route name'
        '(capitalized className + kDefaultRouteNameSuffix)',
        () {
          // arrange
          const className = 'myClassName';

          // assert
          expect(
            RouteConfig.defaultRouteName(className),
            equals('$className${RouteConfig.kDefaultRouteNameSuffix}'.cap),
          );
        },
      );
    });

    group('routeName', () {
      //
      const className = 'MyClassName';
      const routeName = 'MyRouteName';
      //
      RouteConfig getConfig({
        String? name,
        String? replacementInRouteName,
        String className = '',
      }) {
        return RouteConfig(
          pathName: '',
          className: className,
          name: name,
          replacementInRouteName: replacementInRouteName,
        );
      }

      test(
        'returns [name] if it is not null',
        () {
          // arrange
          final routeConfig = getConfig(name: routeName);

          // assert
          expect(routeConfig.routeName, equals(routeName));
        },
      );

      test('returns default route name if [name] is null', () {
        // arrange
        final routeConfig = getConfig(className: className);

        // assert
        expect(
          routeConfig.routeName,
          equals(RouteConfig.defaultRouteName(className).cap),
        );
      });

      test(
        'The case when [name] is empty is treated as if [name] is null',
        () {
          // arrange
          final className = 'MyClassName';
          final routeConfig = getConfig(className: className, name: '');

          // assert
          expect(
            routeConfig.routeName,
            equals(RouteConfig.defaultRouteName(className).cap),
          );
        },
      );

      test(
        '[Screen,Route] pattern makes [MyRoute] out of [MyScreen]',
        () {
          // arrange
          final routeConfig = getConfig(
            className: 'MyScreen',
            replacementInRouteName: 'Screen,Route',
          );

          // assert
          expect(routeConfig.routeName, equals('MyRoute'));
        },
      );

      test(
        '[Screen,Route;Scope,Flow] pattern makes [MyFlow] out of [MyScope]',
        () {
          // arrange
          final routeConfig = getConfig(
            className: 'MyScope',
            replacementInRouteName: 'Screen,Route;Scope,Flow',
          );

          // assert
          expect(routeConfig.routeName, equals('MyFlow'));
        },
      );

      test(
        '[Screen/Scope/View,Route] pattern makes '
        '[MyRoute] out of [MyScreen]/[MyScope]/[MyView]',
        () {
          // arrange
          const pattern = 'Screen/Scope/View,Route';
          const expectedRouteName = 'MyRoute';
          //
          final screenRouteConfig = getConfig(
            className: 'MyScreen',
            replacementInRouteName: pattern,
          );
          final scopeRouteConfig = getConfig(
            className: 'MyScope',
            replacementInRouteName: pattern,
          );
          final viewRouteConfig = getConfig(
            className: 'MyView',
            replacementInRouteName: pattern,
          );

          // assert
          expect(screenRouteConfig.routeName, equals(expectedRouteName));
          expect(scopeRouteConfig.routeName, equals(expectedRouteName));
          expect(viewRouteConfig.routeName, equals(expectedRouteName));
        },
      );
      test(
        '[Screen/Scope/View,Route;Deferred,] pattern makes '
        '[MyRoute] out of [MyScreenDeferred]',
        () {
          // arrange
          final routeConfig = getConfig(
            className: 'MyScreenDeferred',
            replacementInRouteName: 'Screen/Scope/View,Route;Deferred,',
          );

          // assert
          expect(routeConfig.routeName, equals('MyRoute'));
        },
      );
      test(
        'returns default route name if has no pattern matches',
        () {
          // arrange
          final routeConfig = getConfig(
            className: 'MyScreen',
            replacementInRouteName: 'View,Route',
          );

          // assert
          expect(routeConfig.routeName, equals('MyScreenRoute'));
        },
      );
      test(
        'capitalizes route name(myScreen -> MyScreenRoute)',
        () {
          // arrange
          final routeConfig = getConfig(
            className: 'myScreen',
            replacementInRouteName: 'View,Route',
          );

          // assert
          expect(routeConfig.routeName, equals('MyScreenRoute'));
        },
      );

      test(
        'returns default route name if pattern is invalid([Screen;Route])',
        () {
          // arrange
          final routeConfig = getConfig(
            className: 'myScreen',
            replacementInRouteName: 'Screen;Route',
          );

          // assert
          expect(routeConfig.routeName, equals('MyScreenRoute'));
        },
      );
    });
  });
}
