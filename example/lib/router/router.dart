import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/router/route_guards.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/users/users_screen.dart';

export 'package:auto_route/auto_route.dart';

export 'router.gr.dart';

@MaterialAutoRouter(
  routes: <AutoRoute>[
    MaterialRoute<String>(page: HomeScreen, initial: true, guards: [AuthGuard]),
    MaterialRoute(
      path: '/users', page: UsersScreen, name: "users",
//      children: [
//        MaterialRoute(path: '/', page: UserDetails),
//        MaterialRoute(path: '/profile/:id', page: ProfileScreen),
//      ],
    ),
  ],
)
class $Router {}
