import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/profile_screen.dart';
import 'package:example/screens/second_screen.dart';
import 'router.gr.dart';

@MaterialAutoRouter()
class $Router {
  @initial
  @GuardedBy([AuthGuard])
  HomeScreen homeScreen;

  @GuardedBy([AuthGuard])
  SecondScreen secondScreen;

  ProfileScreen profileScreen;

  @CustomRoute(returnType: bool)
  LoginScreen loginScreenDialog;
}

class AuthGuard extends RouteGuard {
  @override
  Future<bool> canNavigate(ExtendedNavigatorState navigator, String routeName,
      Object arguments) async {
    await Future.delayed(Duration(milliseconds: 900));
    return navigator.pushReplacementNamed(Routes.loginScreenDialog);
  }
}
