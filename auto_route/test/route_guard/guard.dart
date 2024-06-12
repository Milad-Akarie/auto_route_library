import 'package:auto_route/auto_route.dart';

class RedirectOrNextGuard extends AutoRouteGuard {
  RedirectOrNextGuard();

  PageRouteInfo? redirectTo;

  void setRedirect(PageRouteInfo? it) {
    redirectTo = it;
  }

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    if (redirectTo != null) {
      resolver.redirect(redirectTo!);
    } else {
      resolver.next();
    }
  }
}
