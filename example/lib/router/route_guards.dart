import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.gr.dart';

class AuthGuard extends RouteGuard {
  Future<bool> canNavigate(
    AutoRouterState router,
    String routeName,
    Object arguments,
  ) async {
    print("guarding $routeName");

    return  router.root.push<bool>(Routes.loginScreen);
  }
}

// global val to mock auth state
bool isLoggedIn = false;
