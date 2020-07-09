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
    CustomRoute(page: HomeScreen, initial: true),
    CustomRoute(path: '/users/:id', page: UsersScreen, children: [
      CustomRoute(path: "", page: ProfileScreen),
      CustomRoute(path: "posts", page: PostsScreen),
    ]),
    CustomRoute(path: '*', page: UnknownRouteScreen)
  ],
)
class $Router {}
