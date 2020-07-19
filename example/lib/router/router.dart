import 'package:auto_route/auto_route_annotations.dart';

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
    CupertinoRoute(page: HomeScreen, initial: true),
    MaterialRoute(
      path: '/users/:id',
      page: UsersScreen,
      name: 'usersScreen',
      children: [
        AdaptiveRoute(path: '/', page: ProfileScreen),
        AdaptiveRoute(
          path: '/posts',
          page: PostsScreen,
          children: [
            AdaptiveRoute(path: '/', page: PostsHome),
            AdaptiveRoute(path: '/details', page: PostDetails),
          ],
        ),
      ],
    ),
    AdaptiveRoute<bool>(path: "/login", page: LoginScreen),
    AdaptiveRoute(path: '*', page: UnknownRouteScreen)
  ],
)
class $Router {}
