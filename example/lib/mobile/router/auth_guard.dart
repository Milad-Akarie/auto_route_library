import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';

bool isAuthenticated = false;

class AuthGuard extends AutoRouteGuard {
  @override
  Future<bool> canNavigate(List<PageRouteInfo> routes, RoutingController router) async {
    if (!isAuthenticated) {
      // ignore: unawaited_futures
      router.push(
        LoginPageRoute(onResult: (loggedIn) {
          if (loggedIn) {
            isAuthenticated = true;
            router.popAndPushAll(routes);
          }
        }),
      );
      return false;
    }
    return true;
  }
}
