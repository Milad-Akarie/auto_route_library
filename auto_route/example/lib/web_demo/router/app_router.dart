//ignore_for_file: public_member_api_docs
import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/services/auth_service.dart';
import 'package:flutter/foundation.dart';

import 'app_router.gr.dart';

@AutoRouterConfig(generateForDir: ['lib/web_demo'])
class AppRouter extends $AppRouter implements AutoRouteGuard {
  late AuthService _authService;

  AppRouter({required AuthService authService}) : _authService = authService;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_authService.isAuthenticated || resolver.routeName == LoginRoute.name) {
      resolver.next();
    } else {
      final redirectRoute = LoginRoute(
        onResult: (didLogin) {
          resolver.resolveNext(didLogin, reevaluateNext: false);
        },
      );
      if (kDebugMode) {
        print('[AppRouter:onNavigation] redirecting to ${redirectRoute.routeName}');
      }
      router.markUrlStateForReplace();
      resolver.redirect(redirectRoute);
    }
  }

  void printRouterStack() {
    print('Current Router Stack:');
    for (var route in this.stack) {
      print("\t- ${route.name} (${route.routeData.name})");
    }
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: MainWebRoute.page, initial: true),
        AutoRoute(path: '/login', page: LoginRoute.page),
        AutoRoute(path: '/verify', page: VerifyRoute.page),
        AutoRoute(
          path: '/user/:userID',
          page: UserRoute.page,
          children: [
            AutoRoute(page: UserProfileRoute.page, initial: true),
            AutoRoute(
              path: 'posts',
              page: UserPostsRoute.page,
              guards: [
                AutoRouteGuard.simple(
                  (resolver, scope) {
                    if (_authService.isVerified) {
                      resolver.next();
                    } else {
                      resolver.redirect(VerifyRoute(onResult: resolver.next));
                    }
                  },
                )
              ],
              children: [
                AutoRoute(path: 'all', page: UserAllPostsRoute.page, initial: true),
                AutoRoute(path: 'favorite', page: UserFavoritePostsRoute.page),
              ],
            ),
          ],
        ),
        AutoRoute(path: '*', page: NotFoundRoute.page),
      ];
}
