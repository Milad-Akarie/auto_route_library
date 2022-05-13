// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

part of 'router.dart';

class _$AppRouter extends RootStackRouter {
  _$AppRouter([GlobalKey<NavigatorState>? navigatorKey]) : super(navigatorKey);

  @override
  final Map<String, PageFactory> pagesMap = {
    FirstRoute.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const FirstPage());
    },
    SecondRoute.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const EmptyRouterPage());
    },
    SecondNested1Route.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const SecondNested1Page());
    },
    SecondNested2Route.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const SecondNested2Page());
    }
  };

  @override
  List<RouteConfig> get routes => [
        RouteConfig('/#redirect',
            path: '/', redirectTo: '/first', fullMatch: true),
        RouteConfig(FirstRoute.name, path: '/first'),
        RouteConfig(SecondRoute.name, path: '/second', children: [
          RouteConfig('#redirect',
              path: '',
              parent: SecondRoute.name,
              redirectTo: 'nested1',
              fullMatch: true),
          RouteConfig(SecondNested1Route.name,
              path: 'nested1', parent: SecondRoute.name),
          RouteConfig(SecondNested2Route.name,
              path: 'nested2', parent: SecondRoute.name)
        ])
      ];
}

/// generated route for
/// [FirstPage]
class FirstRoute extends PageRouteInfo<void> {
  const FirstRoute() : super(FirstRoute.name, path: '/first');

  static const String name = 'FirstRoute';
}

/// generated route for
/// [EmptyRouterPage]
class SecondRoute extends PageRouteInfo<void> {
  const SecondRoute({List<PageRouteInfo>? children})
      : super(SecondRoute.name, path: '/second', initialChildren: children);

  static const String name = 'SecondRoute';
}

/// generated route for
/// [SecondNested1Page]
class SecondNested1Route extends PageRouteInfo<void> {
  const SecondNested1Route() : super(SecondNested1Route.name, path: 'nested1');

  static const String name = 'SecondNested1Route';
}

/// generated route for
/// [SecondNested2Page]
class SecondNested2Route extends PageRouteInfo<void> {
  const SecondNested2Route() : super(SecondNested2Route.name, path: 'nested2');

  static const String name = 'SecondNested2Route';
}
