import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/router/route_guards.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/unknown_route.dart';
import 'package:example/screens/users/sub/profile_screen.dart';
import 'package:example/screens/users/sub/user_posts.dart';
import 'package:example/screens/users/users_screen.dart';

export 'package:auto_route/auto_route.dart';


@MaterialAutoRouter(
  routes: <AutoRoute>[
    MaterialRoute(page: HomeScreen, initial: true),
    MaterialRoute(
      path: '/users/:id?',
      page: UsersScreen,
      children: [
        CustomRoute(path: "/", page: ProfileScreen),
        MaterialRoute(path: "/posts", page: PostsScreen,guards: [AuthGuard]),
      ],
    ),
    CustomRoute<bool>(path: "/login", page: LoginScreen,fullscreenDialog: true),
    MaterialRoute(path: '*', page: UnknownRouteScreen)
  ],
)
class $Router {}
