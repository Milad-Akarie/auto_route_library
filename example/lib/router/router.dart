import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/users/sub/posts_screen.dart';
import 'package:example/screens/users/sub/profile_screen.dart';
import 'package:example/screens/users/sub/sub/posts_details.dart';
import 'package:example/screens/users/sub/sub/posts_home.dart';
import 'package:example/screens/users/users_screen.dart';

export 'package:auto_route/auto_route.dart';

@MaterialAutoRouter(
  routes: <AutoRoute>[
    AdaptiveRoute(page: HomeScreen, initial: true),
    AdaptiveRoute(
      path: '/users',
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
//    AdaptiveRoute(path: '*', page: UnknownRouteScreen)
  ],
)
class $Router {}
