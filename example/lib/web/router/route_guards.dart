import 'package:auto_route/auto_route.dart';

// // guard
// class AuthGuard extends RouteGuard {
//   @override
//   Future<bool> canNavigate(
//     ExtendedNavigatorState navigator,
//     String routeName,
//     Object arguments,
//   ) async {
//     // if isAuthenticated return true;
//     // else
//     return navigator.root.push(Routes.loginScreen);
//   }
// }
bool isAuthenticated = false;

class AuthRouteGuard extends AutoRouteGuard {
  @override
  Future<bool> canNavigate(List<PageRouteInfo> routes, RoutingController router) async {
    if (!isAuthenticated) {
      isAuthenticated = true;
      router.pushAll(routes);
      return false;
    }
    return true;
  }
}
