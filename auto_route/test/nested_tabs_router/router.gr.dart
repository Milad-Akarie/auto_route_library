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
    TabsHostRoute.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const TabsHostPage());
    },
    Tab1Route.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const Tab1Page());
    },
    Tab2Route.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const EmptyRouterPage());
    },
    Tab3Route.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData,
          child: const EmptyRouterPage(),
          maintainState: false);
    },
    Tab2Nested1Route.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const Tab2Nested1Page());
    },
    Tab2Nested2Route.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const Tab2Nested2Page());
    },
    Tab3Nested1Route.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const Tab3Nested1Page());
    },
    Tab3Nested2Route.name: (routeData) {
      return MaterialPageX<dynamic>(
          routeData: routeData, child: const Tab3Nested2Page());
    }
  };

  @override
  List<RouteConfig> get routes => [
        RouteConfig(TabsHostRoute.name, path: '/', children: [
          RouteConfig('#redirect',
              path: '',
              parent: TabsHostRoute.name,
              redirectTo: 'tab1',
              fullMatch: true),
          RouteConfig(Tab1Route.name, path: 'tab1', parent: TabsHostRoute.name),
          RouteConfig(Tab2Route.name,
              path: 'tab2',
              parent: TabsHostRoute.name,
              children: [
                RouteConfig('#redirect',
                    path: '',
                    parent: Tab2Route.name,
                    redirectTo: 'tab2Nested1',
                    fullMatch: true),
                RouteConfig(Tab2Nested1Route.name,
                    path: 'tab2Nested1', parent: Tab2Route.name),
                RouteConfig(Tab2Nested2Route.name,
                    path: 'tab2Nested2', parent: Tab2Route.name)
              ]),
          RouteConfig(Tab3Route.name,
              path: 'tab3',
              parent: TabsHostRoute.name,
              children: [
                RouteConfig('#redirect',
                    path: '',
                    parent: Tab3Route.name,
                    redirectTo: 'tab3Nested1',
                    fullMatch: true),
                RouteConfig(Tab3Nested1Route.name,
                    path: 'tab3Nested1', parent: Tab3Route.name),
                RouteConfig(Tab3Nested2Route.name,
                    path: 'tab3Nested2', parent: Tab3Route.name)
              ])
        ]),
        RouteConfig('*#redirect', path: '*', redirectTo: '/', fullMatch: true)
      ];
}

/// generated route for
/// [TabsHostPage]
class TabsHostRoute extends PageRouteInfo<void> {
  const TabsHostRoute({List<PageRouteInfo>? children})
      : super(TabsHostRoute.name, path: '/', initialChildren: children);

  static const String name = 'TabsHostRoute';
}

/// generated route for
/// [Tab1Page]
class Tab1Route extends PageRouteInfo<void> {
  const Tab1Route() : super(Tab1Route.name, path: 'tab1');

  static const String name = 'Tab1Route';
}

/// generated route for
/// [EmptyRouterPage]
class Tab2Route extends PageRouteInfo<void> {
  const Tab2Route({List<PageRouteInfo>? children})
      : super(Tab2Route.name, path: 'tab2', initialChildren: children);

  static const String name = 'Tab2Route';
}

/// generated route for
/// [EmptyRouterPage]
class Tab3Route extends PageRouteInfo<void> {
  const Tab3Route({List<PageRouteInfo>? children})
      : super(Tab3Route.name, path: 'tab3', initialChildren: children);

  static const String name = 'Tab3Route';
}

/// generated route for
/// [Tab2Nested1Page]
class Tab2Nested1Route extends PageRouteInfo<void> {
  const Tab2Nested1Route() : super(Tab2Nested1Route.name, path: 'tab2Nested1');

  static const String name = 'Tab2Nested1Route';
}

/// generated route for
/// [Tab2Nested2Page]
class Tab2Nested2Route extends PageRouteInfo<void> {
  const Tab2Nested2Route() : super(Tab2Nested2Route.name, path: 'tab2Nested2');

  static const String name = 'Tab2Nested2Route';
}

/// generated route for
/// [Tab3Nested1Page]
class Tab3Nested1Route extends PageRouteInfo<void> {
  const Tab3Nested1Route() : super(Tab3Nested1Route.name, path: 'tab3Nested1');

  static const String name = 'Tab3Nested1Route';
}

/// generated route for
/// [Tab3Nested2Page]
class Tab3Nested2Route extends PageRouteInfo<void> {
  const Tab3Nested2Route() : super(Tab3Nested2Route.name, path: 'tab3Nested2');

  static const String name = 'Tab3Nested2Route';
}
