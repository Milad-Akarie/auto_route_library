import 'package:auto_route/auto_route.dart';

import 'router.gr.dart';

// guard
class AuthGuard extends RouteGuard {
  @override
  Future<bool> canNavigate(
    ExtendedNavigatorState navigator,
    String routeName,
    Object arguments,
  ) async {
    // if isAuthenticated return true;
    // else
    return navigator.root.push(Routes.loginScreen);
  }
}
