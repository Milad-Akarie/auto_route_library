// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/screens/home_screen.dart';
import 'dart:core';
import 'package:example/screens/users/users_screen.dart';
import 'package:example/screens/users/sub/user_details.dart';
import 'package:example/screens/users/sub/profile_screen.dart';

class Routes {
  static const homeScreen = '/';
  static const usersScreen = '/users';
  static const all = {
    homeScreen,
    usersScreen,
  };
}

class Router extends RouterBase {
  @override
  Set<String> get allRoutes => Routes.all;

  @override
  Map<String, RouterBuilder> get subRouters => {
        Routes.usersScreen: () => UsersScreenRouter(),
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
    Routes.usersScreen: (RouteData data) {
      var args = data.getArgs<UsersScreenArguments>(nullOk: false);
      return MaterialPageRoute<dynamic>(
        builder: (context) => UsersScreen(
          id: data.pathParams['id'].stringValue,
          score: args.score,
          limit: data.queryParams['limit'].doubleValue,
        ),
        settings: data,
      );
    },
  };
}

class UsersScreenRoutes {
  static const userDetails = '/';
  static const _profileScreen = '/profile/:id';
  static profileScreen({@required id}) => '/profile/$id';
  static const all = {
    userDetails,
    _profileScreen,
  };
}

class UsersScreenRouter extends RouterBase {
  @override
  Set<String> get allRoutes => UsersScreenRoutes.all;

  @override
  Map<String, RouterBuilder> get subRouters => {
        UsersScreenRoutes._profileScreen: () => ProfileScreenRouter(),
      };

  @override
  Map<String, AutoRouteFactory> get routesMap => _routesMap;

  final _routesMap = <String, AutoRouteFactory>{
    UsersScreenRoutes.userDetails: (RouteData data) {
      return MaterialPageRoute<dynamic>(
        builder: (context) => UserDetails(),
        settings: data,
      );
    },
    UsersScreenRoutes._profileScreen: (RouteData data) {
      var args = data.getArgs<ProfileScreenArguments>(
          orElse: () => ProfileScreenArguments());
      return MaterialPageRoute<dynamic>(
        builder: (context) => ProfileScreen(id: args.id),
        settings: data,
      );
    },
  };
}

class ProfileScreenRoutes {
  static const userDetails = '/user-details';
  static const all = {
    userDetails,
  };
}

class ProfileScreenRouter extends RouterBase {
  @override
  Set<String> get allRoutes => ProfileScreenRoutes.all;

  @override
  Map<String, AutoRouteFactory> get routesMap => _routesMap;

  final _routesMap = <String, AutoRouteFactory>{
    ProfileScreenRoutes.userDetails: (RouteData data) {
      return MaterialPageRoute<dynamic>(
        builder: (context) => UserDetails(),
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
  UsersScreenArguments({@required this.score, this.limit = 0.0});
}

//ProfileScreen arguments holder class
class ProfileScreenArguments {
  final String id;
  ProfileScreenArguments({this.id});
}
