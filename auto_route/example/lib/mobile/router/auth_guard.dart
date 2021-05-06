import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/web_router.gr.dart';
import 'package:flutter/cupertino.dart';

// mock auth state

var isAuthenticated = false;

class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (!isAuthenticated) {
      // ignore: unawaited_futures
      router.push(
        LoginRoute(onLoginResult: (_) {
          isAuthenticated = true;
          router.removeLast();
          resolver.next();
        }),
      );
    } else {
      resolver.next();
    }
  }
}

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  set isAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }
}
