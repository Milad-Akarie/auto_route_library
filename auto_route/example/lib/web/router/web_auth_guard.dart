import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/web_router.dart';

import '../web_main.dart';

class AuthGuard extends AutoRedirectGuard {
  final AuthService authService;

  AuthGuard(this.authService) {
    authService.addListener(reevaluate);
  }

  @override
  Future<bool> canNavigate(RouteMatch route) async{
    return authService.isAuthenticated && authService.isVerified;
  }

  @override
  Future<void> onNavigation(
      NavigationResolver resolver, StackRouter router) async {

    if (await canNavigate(resolver.route)) {
      resolver.next();
    } else {
      redirect(LoginRoute(), resolver: resolver);
    }
  }
}
