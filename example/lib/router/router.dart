import 'package:auto_route/auto_route.dart';
import 'package:example/router/route_guards.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/users/sub/posts_screen.dart';
import 'package:example/screens/users/sub/profile_screen.dart';
import 'package:example/screens/users/sub/sub/posts_details.dart';
import 'package:example/screens/users/sub/sub/posts_home.dart';

import '../demo.dart';
import '../screens/users/users_screen.dart';

@MaterialAutoRouter(
  preferRelativeImports: true,
  routes: <AutoRoute>[
    AutoRoute(page: HomeScreen, initial: true, guards: [AuthRouteGuard]),
    AutoRoute(page: TestPage),
    AutoRoute<String>(
      path: '/users/:id',
      page: UsersScreen,
      children: [
        AutoRoute(path: '', page: ProfileScreen),
        AutoRoute(
          path: 'posts',
          page: PostsScreen,
          children: [
            AutoRoute(path: '', page: PostsHome),
            AutoRoute(path: 'details', page: PostDetails),
          ],
        ),
      ],
    ),
    AutoRoute<bool>(path: '/login', page: LoginScreen),
    // AutoRoute(path: '*', page: UnknownRouteScreen)
  ],
)

// use a different name from 'Router', because a class with the name "Router"
// exists in the material package
class $MyRouterConfig {}
