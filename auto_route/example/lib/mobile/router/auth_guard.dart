import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';

import 'router.gr.dart';

// mock auth state

var isAuthenticated = false;

class AuthGuard extends AutoRouteGuard {
  @override
  Future<bool> canNavigate(RouteMatch routeMatch, StackRouter router) async {
    if (!isAuthenticated) {
      print('gurading ${routeMatch.routeName}');
      // ignore: unawaited_futures
      router.push(LoginRoute(onLoginResult: (success) {
        if (success) {
          print(success);
          isAuthenticated = success;
          router.replace(routeMatch.toRoute());
        }
      }));
      return false;
    }
    return true;
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
