// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/users/users_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'dart:core';

class Routes {
  static const homeScreen = '/';
  static const users = '/users';
  static const loginScreen = '/login';
  static const all = {
    homeScreen,
    users,
    loginScreen,
  };
}

class Router extends RouterBase {
  @override
  Map<String, AutoRouteFactory> get routesMap => _routesMap;

  final _routesMap = <String, AutoRouteFactory>{
    Routes.homeScreen: (RouteData data) {
      return PageRouteBuilder<dynamic>(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
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
    Routes.loginScreen: (RouteData data) {
      var args = data.getArgs<LoginScreenArguments>(
          orElse: () => LoginScreenArguments());
      return PageRouteBuilder<bool>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LoginScreen(id: args.id),
        settings: data,
        fullscreenDialog: true,
      );
    },
  };
}

// *************************************************************************
// Arguments holder classes
// **************************************************************************

//LoginScreen arguments holder class
class LoginScreenArguments {
  final double id;
  LoginScreenArguments({this.id = 20.0});
}
