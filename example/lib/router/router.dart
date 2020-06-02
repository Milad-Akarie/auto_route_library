import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/router/router.gr.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/users/users_screen.dart';
import 'package:flutter/material.dart';

// export 'package:auto_route/auto_route.dart';
// export 'router.gr.txt';

@MaterialAutoRouter()
class Router extends $Router {
  @RoutesList()
  static const routes = <AutoRoute>[
    AutoRoute(page: HomeScreen, initial: true),
    AutoRoute(
      path: '/users/{id}',
      page: UsersScreen,
//      children: [
//        AutoRoute(path: '/details/{user}', page: SecondNested),
//      ],
    ),
  ];
}

class ExtendedRouteSettings extends RouteSettings {
  final String subInitialRoute;
  ExtendedRouteSettings(
      {this.subInitialRoute, @required String name, Object args})
      : super(name: name, arguments: args);
}
