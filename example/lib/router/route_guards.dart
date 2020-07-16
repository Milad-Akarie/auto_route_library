import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.gr.dart';

class AuthGuard extends RouteGuard {
  Future<bool> canNavigate(
    ExtendedNavigatorState navigator,
    String routeName,
    Object arguments,
  ) async {
    print("guarding $routeName");

    return navigator.root.replace<bool, dynamic>(Routes.loginScreen);
  }
}

// global val to mock auth state
bool isLoggedIn = false;
