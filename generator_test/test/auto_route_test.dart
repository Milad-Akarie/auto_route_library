import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Material auto_router', () {
    test(
      'Simple test',
      () async {
        return testGenerator(
          router: r'''
            import 'package:auto_route/annotations.dart';

            class HomeScreen {
              HomeScreen({
                required String title
            });
            }

            @MaterialAutoRouter(
              routes: <AutoRoute>[
                AutoRoute<void>(page: HomeScreen, initial: true),
              ],
            )
            class $AppRouter {}
          ''',
          generatedFile: generatedFile,
        );
      },
    );
  });
}

const generatedFile = r'''// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i1;
import 'package:flutter/material.dart' as _i2;

import 'router.dart' as _i3;

class AppRouter extends _i1.RootStackRouter {
  AppRouter([_i2.GlobalKey<_i2.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i1.PageFactory> pagesMap = {
    HomeScreenRoute.name: (routeData) => _i1.MaterialPageX<void>(
        routeData: routeData,
        builder: (data) {
          final args = data.argsAs<HomeScreenRouteArgs>();
          return _i3.HomeScreen(title: args.title);
        })
  };

  @override
  List<_i1.RouteConfig> get routes =>
      [_i1.RouteConfig(HomeScreenRoute.name, path: '/')];
}

class HomeScreenRoute extends _i1.PageRouteInfo<HomeScreenRouteArgs> {
  HomeScreenRoute({required String title})
      : super(name, path: '/', args: HomeScreenRouteArgs(title: title));

  static const String name = 'HomeScreenRoute';
}

class HomeScreenRouteArgs {
  const HomeScreenRouteArgs({required this.title});

  final String title;
}
''';
