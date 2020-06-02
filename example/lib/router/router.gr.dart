// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:example/screens/users/users_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/users/users_screen.dart';

abstract class Routes {
  static const homeScreen = '/';
  static const usersScreen = '/users';
  static const all = {
    homeScreen,
    usersScreen,
  };
  static get subRoutes => SubRoutes;
}

abstract class SubRoutes {
  static const subHome = '/';
}

class $Router extends RouterBase {
  @override
  Set<String> get allRoutes => Routes.all;

  Map<Type, Function> subRouters = {UsersRouter: () => UsersRouter()};

  @override
  Map<String, RouteFactory> get routesMap => _routesMap;

  final _routesMap = <String, RouteFactory>{
    Routes.homeScreen: (RouteSettings settings) {
      return MaterialPageRoute<dynamic>(
        builder: (context) => HomeScreen(),
        settings: settings,
      );
    },
    Routes.usersScreen: (RouteSettings settings) {
      final data = RouteData<UsersScreenArguments>(
        settings,
        Routes.usersScreen,
      );
      UsersScreenArguments args =
          data.args ?? UsersScreenArguments._fromParams(data.queryParams);

      return MaterialPageRoute<dynamic>(
        settings: data,
        builder: (context) => UsersScreen(
            id: data.pathParams['id'].stringValue,
            score: args.score,
            limit: args.limit),
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
  UsersScreenArguments._fromParams(Parameters params)
      : this.score = params['score'].intValue,
        this.limit = params['limit'].doubleValue ?? 0.0;
}
