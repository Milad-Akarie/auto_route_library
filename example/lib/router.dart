import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/router.gr.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/second_screen.dart';
import 'package:flutter/material.dart';

@CustomRoute.asDefualt()
@AutoRouter(generateNavigator: true)
class $Router {
  @MaterialRoute(initial: true)
  HomeScreen homeScreenRoute;

  @GuardedBy([AuthGuard])
  @MaterialRoute(
      fullscreenDialog: true, maintainState: true, name: 'custom-name')
  SecondScreen secondScreenRoute;

  @CustomRoute(transitionsBuilder: TransitionsBuilders.fadeIn)
  LoginScreen loginScreenDialog;
}

class AuthGuard extends RouteGuard {
  @override
  Future<bool> canNavigate(
      BuildContext context, String routeName, Object arguments) async {
    print('auth Guard');

    final res = await Router.instance.pushNamed(Router.loginScreenDialog);

    return res;
  }
}

class UserRoleGaurd extends RouteGuard {
  @override
  Future<bool> canNavigate(
      BuildContext context, String routeName, Object arguments) async {
    print('UserRoleGaurd Guard');

    Router.instance.pushNamed(Router.loginScreenDialog);
    return true;
  }
}
// static ExtendedNavigator get navigator =>
//     getNavigator<Router>(guardedRoutes: {
//       secondScreenRoute: [AuthGuard]
//     });
