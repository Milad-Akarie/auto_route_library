// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i3;
import 'package:flutter/material.dart' as _i4;

import '../test_page.dart' deferred as _i1;
import 'router.dart' deferred as _i2;

class AppRouter extends _i3.RootStackRouter {
  AppRouter([_i4.GlobalKey<_i4.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i3.PageFactory> pagesMap = {
    FirstRoute.name: (routeData) {
      return _i3.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i3.DeferredWidget(
          _i1.loadLibrary,
          () => _i1.FirstPage(),
        ),
      );
    },
    SecondRoute.name: (routeData) {
      return _i3.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i3.DeferredWidget(
          _i2.loadLibrary,
          () => _i2.EmptyRouterPage(),
        ),
      );
    },
    SecondNested1Route.name: (routeData) {
      return _i3.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i3.DeferredWidget(
          _i2.loadLibrary,
          () => _i2.SecondNested1Page(),
        ),
      );
    },
    SecondNested2Route.name: (routeData) {
      return _i3.MaterialPageX<dynamic>(
        routeData: routeData,
        child: _i3.DeferredWidget(
          _i2.loadLibrary,
          () => _i2.SecondNested2Page(),
        ),
      );
    },
  };

  @override
  List<_i3.RouteConfig> get routes => [
        _i3.RouteConfig(
          FirstRoute.name,
          path: '/',
          deferredLoading: true,
        ),
        _i3.RouteConfig(
          SecondRoute.name,
          path: '/empty-router-page',
          deferredLoading: true,
          children: [
            _i3.RouteConfig(
              SecondNested1Route.name,
              path: '',
              parent: SecondRoute.name,
              deferredLoading: true,
            ),
            _i3.RouteConfig(
              SecondNested2Route.name,
              path: 'second-nested2-page',
              parent: SecondRoute.name,
              deferredLoading: true,
            ),
          ],
        ),
      ];
}

/// generated route for
/// [_i1.FirstPage]
class FirstRoute extends _i3.PageRouteInfo<void> {
  const FirstRoute()
      : super(
          FirstRoute.name,
          path: '/',
        );

  static const String name = 'FirstRoute';
}

/// generated route for
/// [_i2.EmptyRouterPage]
class SecondRoute extends _i3.PageRouteInfo<void> {
  const SecondRoute({List<_i3.PageRouteInfo>? children})
      : super(
          SecondRoute.name,
          path: '/empty-router-page',
          initialChildren: children,
        );

  static const String name = 'SecondRoute';
}

/// generated route for
/// [_i2.SecondNested1Page]
class SecondNested1Route extends _i3.PageRouteInfo<void> {
  const SecondNested1Route()
      : super(
          SecondNested1Route.name,
          path: '',
        );

  static const String name = 'SecondNested1Route';
}

/// generated route for
/// [_i2.SecondNested2Page]
class SecondNested2Route extends _i3.PageRouteInfo<void> {
  const SecondNested2Route()
      : super(
          SecondNested2Route.name,
          path: 'second-nested2-page',
        );

  static const String name = 'SecondNested2Route';
}
