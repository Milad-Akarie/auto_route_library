import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/web_router.gr.dart';

import 'package:example/web_demo/web_main.dart';

//ignore_for_file: public_member_api_docs
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this.authService);
  final AuthService authService;

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    if (authService.isAuthenticated) {
      resolver.next(true);
    } else {
      resolver.redirectUntil(WebLoginRoute());
    }
  }
}
