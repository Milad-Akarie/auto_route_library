import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/router/route_guards.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/users/sub/profile_screen.dart';
import 'package:example/screens/users/sub/user_details.dart';
import 'package:example/screens/users/users_screen.dart';

export 'package:auto_route/auto_route.dart';

export 'router.gr.dart';

@MaterialAutoRouter(
  routes: <AutoRoute>[
    CustomRoute(page: HomeScreen, initial: true,
//      guards: [AuthGuard],
        ),
    MaterialRoute(
      path: '/users',
      page: UsersScreen,
      name: "users",
//      children: [
//        CustomRoute(path: '/', page: UserDetails, guards: [AuthGuard]),
//        MaterialRoute(path: '/profile', page: ProfileScreen),
//      ],
    ),
//    MaterialRoute(path: "/users/profile", page: ProfileScreen),
    CustomRoute<bool>(path: "/login", page: LoginScreen, fullscreenDialog: true),
  ],
)
class $Router {}
