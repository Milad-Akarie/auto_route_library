import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/web_router.gr.dart';

import '../web_main.dart';

class AuthGuard extends AutoRouteGuard {
  final AuthService authService;

  AuthGuard(this.authService);

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    if (authService.isAuthenticated) {
      resolver.next();
    } else {
      router.replace(WebLoginRoute(resolver: resolver));
    }
  }
}
