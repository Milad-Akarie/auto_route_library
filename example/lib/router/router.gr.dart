// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/screens/home_screen.dart';
import 'dart:core';
import 'package:example/router/route_guards.dart';
import 'package:example/screens/users/users_screen.dart';

class Routes {
  static const homeScreen = '/';
  static const users = '/users';
  static const all = {
    homeScreen,
    users,
  };
}

class Router extends RouterBase {
  @override
  Map<String, List<Type>> get guardedRoutes => {
        Routes.homeScreen: [AuthGuard],
      };
  @override
  Map<String, AutoRouteFactory> get routesMap => _routesMap;

  final _routesMap = <String, AutoRouteFactory>{
    Routes.homeScreen: (RouteData data) {
      return MaterialPageRoute<String>(
        builder: (context) => HomeScreen(),
        settings: data,
      );
    },
    Routes.users: (RouteData data) {
      return MaterialPageRoute<dynamic>(
        builder: (context) => UsersScreen(
          id: data.pathParams['id'].stringValue,
          score: data.queryParams['score'].intValue,
          limit: data.queryParams['limit'].doubleValue,
        ),
        settings: data,
      );
    },
  };
}
