// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/screens/nested_screens/nested_screen.dart';
import 'package:example/screens/nested_screens/nested_screen_two.dart';

abstract class NestedRoutes {
  static const nestedScreen = '/second/{id}/';
  static const nestedScreenTwo = '/second/{id}/nested';
  static const all = {
    nestedScreen,
    nestedScreenTwo,
  };
}

class $NestedRouter extends RouterBase {
  @override
  Set<String> get allRoutes => NestedRoutes.all;

  @override
  Map<String, RouteFactory> get routesMap => _routesMap;

  final _routesMap = <String, RouteFactory>{
    NestedRoutes.nestedScreen: (RouteSettings settings) {
      final data = RouteData<NestedScreenArguments>(
        settings,
        NestedRoutes.nestedScreen,
      );
      NestedScreenArguments args =
          data.args ?? NestedScreenArguments._fromParams(data.queryParams);
      return MaterialPageRoute<dynamic>(
        builder: (context) =>
            NestedScreen(key: args.key, id: data.pathParams['id'].stringValue),
        settings: settings,
      );
    },
    NestedRoutes.nestedScreenTwo: (RouteSettings settings) {
      final data = RouteData<NestedScreenTwoArguments>(
        settings,
        NestedRoutes.nestedScreenTwo,
      );
      NestedScreenTwoArguments args =
          data.args ?? NestedScreenTwoArguments._fromParams(data.queryParams);
      return MaterialPageRoute<dynamic>(
        builder: (context) => NestedScreenTwo(
            title: args.title, id: data.pathParams['id'].stringValue),
        settings: settings,
      );
    },
  };
}

// *************************************************************************
// Arguments holder classes
// **************************************************************************

//NestedScreen arguments holder class
class NestedScreenArguments {
  final Key key;
  NestedScreenArguments({this.key});
  NestedScreenArguments._fromParams(Parameters params)
      : this.key = params['key'].value;
}

//NestedScreenTwo arguments holder class
class NestedScreenTwoArguments {
  final dynamic title;
  NestedScreenTwoArguments({this.title});
  NestedScreenTwoArguments._fromParams(Parameters params)
      : this.title = params['title'].value;
}
