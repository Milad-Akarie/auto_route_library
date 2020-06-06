// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/users/users_router.dart';
import 'package:example/screens/users/users_screen.dart';
import 'package:flutter/material.dart';

abstract class Routes {
  static const homeScreen = '/';
  static const usersScreen = '/users/{id}';
  static const all = {
    homeScreen,
    usersScreen,
  };
}

class $Router extends RouterBase {
  @override
  Set<String> get allRoutes => Routes.all;

  @override
  Map<String, RouterBuilder> get nestedRouters => {
        Routes.usersScreen: () => UsersRouter(),
      };

  @override
  Map<String, AutoRouteFactory> get routesMap => _routesMap;

  final _routesMap = <String, AutoRouteFactory>{
    Routes.homeScreen: (RouteData data) {
      return MaterialPageRoute<dynamic>(
        builder: (context) => HomeScreen(),
        settings: data,
      );
    },
    Routes.usersScreen: (RouteData data) {
      var args = data.getArgs<UsersScreenArguments>();
      UsersScreenArguments typedArgs = args ?? UsersScreenArguments();
      return MaterialPageRoute<dynamic>(
        builder: (context) => UsersScreen(
          id: data.pathParams['id'].stringValue,
          score: typedArgs.score,
          limit: typedArgs.limit,
        ),
        settings: data,
      );
    },
  };
}

// *************************************************************************
// Arguments holder classes
// **************************************************************************

//UsersScreen arguments holder class
class UsersScreenArguments {
  final int score;
  final double limit;

  UsersScreenArguments({this.score, this.limit = 0.0});
}
