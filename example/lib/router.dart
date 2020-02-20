import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/models.dart';
import 'package:example/router.gr.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/second_screen.dart';
import 'package:flutter/material.dart';

@AutoRouter()
class $Router {
  @MaterialRoute(initial: true)
  HomeScreen homeScreen;

  @GuardedBy([AuthGuard])
  SecondScreen secondScreen;

  @CustomRoute(returnType: CustomModel)
  LoginScreen loginScreenDialog;
}

class AuthGuard extends RouteGuard {
  @override
  Future<bool> canNavigate(
      BuildContext context, String routeName, Object arguments) async {
    final res = await Router.navigator.pushNamed(Router.loginScreenDialog);

    return res;
  }
}

class UserRoleGaurd extends RouteGuard {
  @override
  Future<bool> canNavigate(
      BuildContext context, String routeName, Object arguments) async {
    print('UserRoleGaurd Guard');

    // Router.navigator.pushNamed(Router.loginScreenDialog);
    return true;
  }
}
// static ExtendedNavigator get navigator =>
//     getNavigator<Router>(guardedRoutes: {
//       secondScreenRoute: [AuthGuard]
//     });
