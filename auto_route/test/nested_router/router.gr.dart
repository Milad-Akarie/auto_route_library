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
        routeData: routeData,
        child: const FirstPage(),
      );
    },
    SecondRoute.name: (routeData) {
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: const EmptyRouterPage(),
      );
    },
    SecondNested1Route.name: (routeData) {
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: const SecondNested1Page(),
      );
    },
    SecondNested2Route.name: (routeData) {
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: const SecondNested2Page(),
      );
    },
  };

  @override
  List<AutoRouteConfig> get routes => [
        AutoRouteConfig(
          '/#redirect',
          name: '/',
          redirectTo: '/first',
          fullMatch: true,
        ),
        AutoRouteConfig(
          FirstRoute.name,
          name: '/first',
        ),
        AutoRouteConfig(
          SecondRoute.name,
          name: '/second',
          children: [
            AutoRouteConfig(
              '#redirect',
              name: '',
              parent: SecondRoute.name,
              redirectTo: 'nested1',
              fullMatch: true,
            ),
            AutoRouteConfig(
              SecondNested1Route.name,
              name: 'nested1',
              parent: SecondRoute.name,
            ),
            AutoRouteConfig(
              SecondNested2Route.name,
              name: 'nested2',
              parent: SecondRoute.name,
            ),
          ],
        ),
      ];
}

/// generated route for
/// [FirstPage]
class FirstRoute extends PageRouteInfo<void> {
  const FirstRoute()
      : super(
          FirstRoute.name,
          name: '/first',
        );

  static const String name = 'FirstRoute';
}

/// generated route for
/// [EmptyRouterPage]
class SecondRoute extends PageRouteInfo<void> {
  const SecondRoute({List<PageRouteInfo>? children})
      : super(
          SecondRoute.name,
          name: '/second',
          initialChildren: children,
        );

  static const String name = 'SecondRoute';
}

/// generated route for
/// [SecondNested1Page]
class SecondNested1Route extends PageRouteInfo<void> {
  const SecondNested1Route()
      : super(
          SecondNested1Route.name,
          name: 'nested1',
        );

  static const String name = 'SecondNested1Route';
}

/// generated route for
/// [SecondNested2Page]
class SecondNested2Route extends PageRouteInfo<void> {
  const SecondNested2Route()
      : super(
          SecondNested2Route.name,
          name: 'nested2',
        );

  static const String name = 'SecondNested2Route';
}
