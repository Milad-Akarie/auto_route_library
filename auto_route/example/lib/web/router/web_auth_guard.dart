import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/web_router.dart';
import 'package:flutter/cupertino.dart';

class AuthGuard extends AutoRedirectGuard {
  final AuthService authService;

  AuthGuard(this.authService) {
    authService.addListener(() {
      if (!authService.isAuthenticated) {
        // should be called when the logic effecting this guard changes
        // e.g when the user is no longer authenticated
        reevaluate();
      }
    });
  }

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (authService.isAuthenticated) return resolver.next();
    router.push(
      LoginRoute(onLoginResult: (_) {
        resolver.next();
        router.removeLast();
      }),
    );
  }
}

// mock auth state
class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  set isAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }
}
