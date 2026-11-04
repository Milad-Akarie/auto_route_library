import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/web_router.gr.dart';

import 'package:example/web_demo/web_main.dart';

class AuthGuard extends AutoRouteGuard {
  AuthGuard(this.authService);
  final AuthService authService;

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    if (authService.isAuthenticated) {
      resolver.next();
    } else {
      unawaited(resolver.redirectUntil(WebLoginRoute()));
    }
  }
}
