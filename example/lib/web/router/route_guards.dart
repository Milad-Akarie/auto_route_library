import 'package:auto_route/auto_route.dart';

bool isAuthenticated = false;

class AuthRouteGuard extends AutoRouteGuard {
  @override
  Future<bool> canNavigate(List<PageRouteInfo> routes, StackController router) async {
    if (!isAuthenticated) {
      isAuthenticated = true;
      router.pushAll(routes);
      return false;
    }
    return true;
  }
}
