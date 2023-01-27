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

const generatedFile =
    r'''// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

import 'package:auto_route/auto_route.dart' as _i2;
import 'package:flutter/material.dart' as _i3;

import 'router.dart' as _i1;

class AppRouter extends _i2.RootStackRouter {
  AppRouter([_i3.GlobalKey<_i3.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i2.PageFactory> pagesMap = {
    HomeScreenRoute.name: (routeData) {
      final args = routeData.argsAs<HomeScreenRouteArgs>();
      return _i2.MaterialPageX<void>(
          routeData: routeData, child: _i1.HomeScreen(title: args.title));
    }
  };

  @override
  List<_i2.RouteConfig> get routes =>
      [_i2.RouteConfig(HomeScreenRoute.name, path: '/')];
}

/// generated route for
/// [_i1.HomeScreen]
class HomeScreenRoute extends _i2.PageRouteInfo<HomeScreenRouteArgs> {
  HomeScreenRoute({required String title})
      : super(HomeScreenRoute.name,
            path: '/', args: HomeScreenRouteArgs(title: title));

  static const String name = 'HomeScreenRoute';
}

class HomeScreenRouteArgs {
  const HomeScreenRouteArgs({required this.title});

  final String title;

  @override
  String toString() {
    return 'HomeScreenRouteArgs{title: $title}';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is HomeScreenRouteArgs && this.title == other.title);
  }

  @override
  int get hashCode => Object.hashAll([title.hashCode]);
}
''';
