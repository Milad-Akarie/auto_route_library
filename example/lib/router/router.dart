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
    MaterialRoute(page: HomeScreen, initial: true),
    MaterialRoute(
      path: '/users/:id',
      page: UsersScreen,
      children: <AutoRoute>[
        // path: '/' is the same as setting initial to true
        MaterialRoute(path: '/', page: ProfileScreen),
        MaterialRoute(path: '/posts', page: PostsScreen),
      ],
    ),
    MaterialRoute(path: '*',page: UnknownRouteScreen)
  ],
)
class $Router {}
