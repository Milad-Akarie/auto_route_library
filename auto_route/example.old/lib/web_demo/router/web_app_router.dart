import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/app.dart';
import 'package:example/web_demo/auth_service.dart';
import 'package:example/web_demo/router/web_app_router.gr.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Routes of the web example app.
///
/// The main page needs a signed-in user, and the posts of a user also need a
/// verified one. Both guards redirect to their own page.
@AutoRouterConfig(generateForDir: ['lib/web_demo'])
class WebAppRouter extends RootStackRouter {
  /// Takes the [AuthService] that the guards ask.
  new(this.authService);

  /// The sign-in state the guards check.
  AuthService authService;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      initial: true,
      page: MainWebRoute.page,
      guards: [
        AutoRouteGuard.simple((resolver, _) {
          if (authService.isAuthenticated) {
            resolver.next();
          } else {
            unawaited(resolver.redirectUntil(WebLoginRoute()));
          }
        }, debugLabel: 'AuthGuard'),
      ],
    ),
    AutoRoute(path: '/login', page: WebLoginRoute.page),
    AutoRoute(path: '/verify', page: WebVerifyRoute.page),
    AutoRoute(
      path: '/user/:userID',
      page: UserRoute.page,
      children: [
        AutoRoute(page: UserProfileRoute.page, initial: true),
        AutoRoute(
          path: 'posts',
          page: UserPostsRoute.page,
          guards: [
            AutoRouteGuard.simple((resolver, scope) {
              debugPrint(
                'Verify Guard: ${resolver.routeName}, isRev: '
                '${resolver.isReevaluating}',
              );
              if (authService.isVerified) {
                resolver.next();
              } else {
                unawaited(resolver.redirectUntil(WebVerifyRoute()));
              }
            }, debugLabel: 'VerifyGuard'),
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

/// Main page of the web example, with buttons to open a user and to sign out.
@RoutePage()
class MainWebPage extends StatelessWidget {
  /// All arguments are optional.
  const new({super.key, this.onNavigate, this.onShowUserPosts});

  /// Replaces the default of the button that opens user 2.
  final VoidCallback? onNavigate;

  /// Not used by this page.
  final VoidCallback? onShowUserPosts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AutoLeadingButton()),
      body: Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            const Text('HomePage', style: TextStyle(fontSize: 30)),
            Padding(
              padding: const .symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed:
                    onNavigate ??
                    () async {
                      await context.pushRoute(
                        UserRoute(
                          id: 2,
                          query: const ['value1', 'value2'],
                          fragment: 'frag',
                        ),
                      );
                    },
                child: const Text('Navigate to user/2'),
              ),
            ),
            Padding(
              padding: const .symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  App.of(context).authService.isAuthenticated = false;
                },
                child: const Text('Logout'),
              ),
            ),
            if (kIsWeb)
              ElevatedButton(
                onPressed: () {
                  final currentState = (context.router.pathState as int?) ?? 0;
                  context.router.pushPathState(currentState + 1);
                },
                child: AnimatedBuilder(
                  animation: context.router.navigationHistory,
                  builder: (context, _) {
                    return Text(
                      'Update State: ${context.router.pathState ?? 'null'}',
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
