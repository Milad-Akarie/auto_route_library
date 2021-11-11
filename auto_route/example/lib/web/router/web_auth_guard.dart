import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/web_router.dart';

import '../web_main.dart';

class AuthGuard extends AutoRedirectGuard {
  final AuthService authService;

  AuthGuard(this.authService) {
    authService.addListener(reevaluate);
  }

  @override
  Future<void> onNavigation(
      NavigationResolver resolver, StackRouter router) async {
    if (authService.isAuthenticated) {
      resolver.next();
    } else {
      redirect(LoginRoute(), resolver: resolver);
    }
  }
}
