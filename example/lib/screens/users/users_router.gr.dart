// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/screens/users/sub/user_details.dart';
import 'package:example/screens/users/sub/profile_screen.dart';

abstract class UserRoutes {
  static const userDetails = '/users/';
  static const profileScreen = '/users/profile-screen';
  static const all = {
    userDetails,
    profileScreen,
  };
}

class $UsersRouter extends RouterBase {
  @override
  Set<String> get allRoutes => UserRoutes.all;

  @override
  Map<String, RouteFactory> get routesMap => _routesMap;

  final _routesMap = <String, RouteFactory>{
    UserRoutes.userDetails: (RouteSettings settings) {
      return MaterialPageRoute<dynamic>(
        builder: (context) => UserDetails(),
        settings: settings,
      );
    },
    UserRoutes.profileScreen: (RouteSettings settings) {
      final data = RouteData<ProfileScreenArguments>(
        settings,
        UserRoutes.profileScreen,
      );
      ProfileScreenArguments args =
          data.args ?? ProfileScreenArguments._fromParams(data.queryParams);
      return MaterialPageRoute<dynamic>(
        builder: (context) => ProfileScreen(title: args.title, id: args.id),
        settings: settings,
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
  ProfileScreenArguments._fromParams(Parameters params)
      : this.title = params['title'].value,
        this.id = params['id'].stringValue;
}
