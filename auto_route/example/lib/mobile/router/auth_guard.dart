//ignore_for_file: public_member_api_docs
import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/cupertino.dart';

// mock auth state
var isAuthenticated = false;

class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (!isAuthenticated) {
      // ignore: unawaited_futures
      resolver.redirectUntilResolved(
        LoginRoute(onLoginResult: (_) {
          isAuthenticated = true;
          resolver.next();
        }),
      );
    } else {
      resolver.next(true);
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
