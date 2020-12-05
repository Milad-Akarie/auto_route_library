import 'package:auto_route/auto_route.dart';
import 'package:example/router/route_guards.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/users/sub/posts_screen.dart';
import 'package:example/screens/users/sub/profile_screen.dart';
import 'package:example/screens/users/sub/sub/posts_details.dart';
import 'package:example/screens/users/sub/sub/posts_home.dart';
import 'package:example/screens/users/users_screen.dart';
import 'package:flutter/material.dart';

import '../demo.dart';

@MaterialAutoRouter(
  routes: <AutoRoute>[
    AutoRoute(
      page: HomeScreen,
      initial: true,
      guards: [AuthRouteGuard],
      // maintainState: true,
    ),
    AutoRoute(page: TestPage),
    AutoRoute(
      path: '/users/:id',
      page: UsersScreen,
      children: [
        AutoRoute(path: 'home', page: ProfileScreen),
        AutoRoute(
          path: 'posts',
          page: PostsScreen,
          children: [
            AutoRoute(path: 'home', page: PostsHome),
            AutoRoute(path: 'details', page: PostDetails),
          ],
        ),
      ],
    ),
    AutoRoute(path: '/login', page: LoginScreen),
    // AutoRoute(path: '*', page: UnknownRouteScreen)
  ],
)
// use a different name from 'Router', because a class with the name "Router"
// exists in the material package
class $MyRouterConfig {
  static Widget customTrans(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }

  static Route myRouteBuilder(BuildContext context, CustomPage page) {
    print('My route builder ${page.durationInMilliseconds}');
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page.child,
      settings: page,
    );
  }
}
