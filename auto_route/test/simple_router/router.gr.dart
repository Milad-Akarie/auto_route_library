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
          routeData: routeData, child: const SecondPage());
    },
    ThirdRoute.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const ThirdPage());
    }
  };

  @override
  List<RouteConfig> get routes => [
        RouteConfig(FirstRoute.name, path: '/'),
        RouteConfig(SecondRoute.name, path: '/second-page'),
        RouteConfig(ThirdRoute.name, path: '/third-page')
      ];
}

/// generated route for
/// [FirstPage]
class FirstRoute extends PageRouteInfo<void> {
  const FirstRoute() : super(FirstRoute.name, path: '/');

  static const String name = 'FirstRoute';
}

/// generated route for
/// [SecondPage]
class SecondRoute extends PageRouteInfo<void> {
  const SecondRoute() : super(SecondRoute.name, path: '/second-page');

  static const String name = 'SecondRoute';
}

/// generated route for
/// [ThirdPage]
class ThirdRoute extends PageRouteInfo<void> {
  const ThirdRoute() : super(ThirdRoute.name, path: '/third-page');

  static const String name = 'ThirdRoute';
}
