//ignore_for_file: public_member_api_docs
import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/app_router.gr.dart';
import 'package:example/web_demo/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class AuthGuard extends AutoRouteGuard {
  final AuthService authService;

  AuthGuard({required this.authService});

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    if (authService.isAuthenticated) {
      if(kDebugMode) {
        print('AuthGuard: isAuthenticated');
      }
      resolver.resolveNext(true, reevaluateNext: true);
    } else {
      final replaceRouteWith = LoginRoute(
        onResult: (didLogin) {
          resolver.resolveNext(true, reevaluateNext: true);
        },
      );
      if(kDebugMode) {
        print('AuthGuard: redirecting to ${replaceRouteWith.routeName}');
      }
      router.replace(replaceRouteWith);
    }
  }
}