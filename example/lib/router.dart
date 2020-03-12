import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/second_screen.dart';
import 'router.gr.dart';

export 'package:auto_route/auto_route.dart';
export 'router.gr.dart';

@MaterialAutoRouter()
class $Router {
  @initial
  @GuardedBy([AuthGuard])
  HomeScreen homeScreen;

  @GuardedBy([AuthGuard])
  SecondScreen secondScreen;

  @CustomRoute(returnType: bool)
  LoginScreen loginScreenDialog;
}

class AuthGuard extends RouteGuard {
  @override
  Future<bool> canNavigate(ExtendedNavigatorState navigator, String routeName,
      Object arguments) async {
    if (!await isLoggedIn()) {
      navigator.pushReplacementNamed(Routes.loginScreenDialog);
      return false;
    }
    return true;
  }
}

Future<bool> isLoggedIn() async =>
    Future.delayed(Duration(milliseconds: 300), () => isUserLoggedIn);

bool isUserLoggedIn = false;
