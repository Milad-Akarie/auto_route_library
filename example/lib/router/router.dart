import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/unknown_route.dart';
import 'package:example/screens/users/sub/profile_screen.dart';
import 'package:example/screens/users/sub/user_posts.dart';
import 'package:example/screens/users/users_screen.dart';

export 'package:auto_route/auto_route.dart';

export 'router.gr.dart';

@MaterialAutoRouter(
  routes: <AutoRoute>[
    AdaptiveRoute(page: HomeScreen, initial: true),
    AdaptiveRoute(path: '/users/:id', page: UsersScreen, children: [
      AdaptiveRoute(path: "/", page: ProfileScreen),
      AdaptiveRoute(path: "/posts", page: PostsScreen),
    ]),
    AdaptiveRoute(path: '*', page: UnknownRouteScreen)
  ],
)
class $Router {}
