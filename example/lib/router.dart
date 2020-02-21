import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/second_screen.dart';
import 'package:example/screens/third_screen.dart';
import 'package:flutter/material.dart';

@CustomAutoRouter(
    transitionsBuilder: TransitionsBuilders.slideLeft,
    opaque: true,
    barrierDismissible: true,
    durationInMilliseconds: 300,
    generateRouteList: true)
// @CupertinoAutoRouter()
class $Router {
  @initial
  HomeScreen homeScreen;

  @GuardedBy([AuthGuard])
  SecondScreen secondScreen;

  @GuardedBy([AuthGuard])
  ProfileScreen profileScreen;

  @CustomRoute(returnType: bool)
  LoginScreen loginScreenDialog;
}

class AuthGuard extends RouteGuard {
  @override
  Future<bool> canNavigate(
      BuildContext context, String routeName, Object arguments) async {
     return true;
  }
}

