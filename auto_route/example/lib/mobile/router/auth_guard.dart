import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'router.gr.dart';

// mock auth state

class AuthGuard extends AutoRouteGuard {
  @override
  Future<bool> canNavigate(List<PageRouteInfo> pendingRoutes, StackRouter router) async {
    var context = router.navigatorKey.currentContext;

    if (!context!.read<AuthService>().isAuthenticated) {
      // ignore: unawaited_futures
      router.rootAsStackRouter.push(LoginRoute(
          showBackButton: pendingRoutes.first is! HomeRoute,
          onLoginResult: (success) {
            if (success) {
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
