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
    print('guarding $routeName');

    // final prefs = await SharedPreferences.getInstance();
    // print('token: ${prefs.getString('token')}');
    if (!await isLoggedIn()) {
      final res =
          await navigator.pushReplacementNamed(Routes.loginScreenDialog);
      print(res);
      return res == true;
    } else
      return true;
  }
}

Future<bool> isLoggedIn() async =>
    Future.delayed(Duration(milliseconds: 20), () => isUserLoggedIn);

bool isUserLoggedIn = false;
