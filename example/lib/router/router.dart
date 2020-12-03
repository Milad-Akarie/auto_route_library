import 'package:auto_route/auto_route.dart';
import 'package:example/router/route_guards.dart';

import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/unknown_route.dart';
import '../screens/users/sub/posts_screen.dart';
import '../screens/users/sub/profile_screen.dart';
import '../screens/users/sub/sub/posts_details.dart';
import '../screens/users/sub/sub/posts_home.dart';
import '../screens/users/users_screen.dart';

@MaterialAutoRouter(
  generateNavigationHelperExtension: true,
  routes: <AutoRoute>[
    AutoRoute(page: HomeScreen, initial: true, guards: [AuthGuard]),
    // AutoRoute(page: TestPage),
    AutoRoute<String>(
      path: '/users/:id',
      page: UsersScreen,
      name: 'usersScreen',
      children: [
        AutoRoute(path: '/', page: ProfileScreen),
        AutoRoute(
          path: '/posts',
          page: PostsScreen,
          children: [
            AutoRoute(path: '/', page: PostsHome),
            AutoRoute(path: '/details', page: PostDetails),
          ],
        ),
      ],
    ),
    AutoRoute<bool>(path: '/login', page: LoginScreen),
    AutoRoute(path: '*', page: UnknownRouteScreen)
  ],
)

// use a different name from 'Router', because a class with the name "Router"
// exists in the material package
class $AppRouter {}
