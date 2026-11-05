import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/web_router.gr.dart';

import 'package:example/web_demo/web_main.dart';

/// Sends users who are not signed in to the web login page, and lets the others
/// through.
class AuthGuard extends AutoRouteGuard {
  /// Takes the [AuthService] to ask.
  new(this.authService);

  /// The sign-in state this guard checks.
  final AuthService authService;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    if (authService.isAuthenticated) {
      resolver.next();
    } else {
      unawaited(resolver.redirectUntil(WebLoginRoute()));
    }
  }
}
