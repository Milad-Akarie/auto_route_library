import 'package:auto_route/auto_route.dart';
import 'router.gr.dart';
// guard
class AuthGuard extends RouteGuard {
  Future<bool> canNavigate(
    ExtendedNavigatorState navigator,
    String routeName,
    Object arguments,
  ) async {
    return navigator.root.replace(Routes.loginScreen);
  }
}

