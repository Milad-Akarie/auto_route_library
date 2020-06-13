import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/users/sub/profile_screen.dart';
import 'package:example/screens/users/sub/user_details.dart';
import 'package:example/screens/users/users_screen.dart';

export 'package:auto_route/auto_route.dart';

export 'router.gr.dart';

@MaterialAutoRouter()
class $Router {
  @RoutesList()
  static const routes = <AutoRoute>[
    MaterialRoute<String>(page: HomeScreen, initial: true),
    MaterialRoute(
      path: '/users',
      page: UsersScreen,
      children: [
        MaterialRoute(path: '/', page: UserDetails),
        MaterialRoute(
          path: '/profile/:id',
          page: ProfileScreen,
          children: [
            MaterialRoute(page: UserDetails),
          ],
        ),
      ],
    ),
  ];
}
