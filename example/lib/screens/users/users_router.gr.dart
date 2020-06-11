// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart';
import 'package:example/screens/users/sub/profile_screen.dart';
import 'package:example/screens/users/sub/user_details.dart';
import 'package:flutter/material.dart';

abstract class UserRoutes {
  static const userDetails = '/';
  static const profileScreen = '/profile/:id';
  static const all = {
    userDetails,
    profileScreen,
  };
}

class $UsersRouter extends RouterBase {
  @override
  Set<String> get allRoutes => UserRoutes.all;

  @override
  Map<String, AutoRouteFactory> get routesMap => _routesMap;

  final _routesMap = <String, AutoRouteFactory>{
    UserRoutes.userDetails: (RouteData data) {
      return MaterialPageRoute<dynamic>(
        builder: (context) => UserDetails(),
        settings: data,
      );
    },
    UserRoutes.profileScreen: (RouteData data) {
      ProfileScreenArguments args = ProfileScreenArguments();
      return MaterialPageRoute<dynamic>(
        builder: (context) => ProfileScreen(title: args.title, id: args.id),
        settings: data,
      );
    },
  };
}

// *************************************************************************
// Arguments holder classes
// **************************************************************************

//ProfileScreen arguments holder class
class ProfileScreenArguments {
  final dynamic title;
  final String id;
  ProfileScreenArguments({this.title, this.id});
}
