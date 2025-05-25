import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:example/web_demo/router/web_router.gr.dart';

//ignore_for_file: public_member_api_docs
class AuthGuard extends AutoRouteGuard {
  final AuthService authService;

  AuthGuard(this.authService);

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    if (authService.isAuthenticated) {
      resolver.resolveNext(true, reevaluateNext: true);
    } else {
      router.replace(WebLoginRoute(
        onResult: (didLogin) {
          resolver.resolveNext(true, reevaluateNext: true);
        },
      ));
    }
  }
}
