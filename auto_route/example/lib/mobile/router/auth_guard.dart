import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'router.gr.dart';

// mock auth state

var isAuthenticated = false;

class AuthGuard extends AutoRouteGuard {
  @override
  Future<bool> canNavigate(List<PageRouteInfo> pendingRoutes, StackRouter router) async {
    if (!isAuthenticated) {
      // ignore: unawaited_futures
      router.push(LoginRoute(onLoginResult: (success) {
        if (success) {
          isAuthenticated = success;
          router.replaceAll(pendingRoutes);
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
