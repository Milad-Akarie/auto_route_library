import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/router.gr.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/second_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:auto_route/auto_route.dart';
export 'router.gr.dart';

@MaterialAutoRouter(generateNavigationHelper: true)
class $Router {
  @initial
  @GuardedBy([AuthGuard])
  HomeScreen homeScreen;

  @GuardedBy([AuthGuard])
  @CustomRoute(
      transitionsBuilder: TransitionsBuilders.fadeIn,
      durationInMilliseconds: 300)
  SecondScreen secondScreen;

  @CustomRoute(returnType: bool)
  LoginScreen loginScreenDialog;
}

// static ExtendedNavigatorState get navigator =>
//     ExtendedNavigator.ofRouter<Router>();
class AuthGuard extends RouteGuard {
  @override
  Future<bool> canNavigate(ExtendedNavigatorState navigator, String routeName,
      Object arguments) async {
    // return true;
    return routeName == '/';
    // return false;
    final prefs = await SharedPreferences.getInstance();

    // await Future.delayed(Duration(seconds: 1));
    if (prefs.getString('token') == null) {
      // final res =
      //     await navigator.pushReplacementNamed(Routes.loginScreenDialog);
      navigator.pushReplacementNamed(Routes.loginScreenDialog);
      return false;
    } else
      return true;
  }
}
