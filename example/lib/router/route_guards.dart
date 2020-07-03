import 'package:auto_route/auto_route.dart';

class AuthGuard extends RouteGuard {
  Future<bool> canNavigate(
    ExtendedNavigatorState navigator,
    String routeName,
    Object arguments,
  ) async {
    return true;
  }
}
