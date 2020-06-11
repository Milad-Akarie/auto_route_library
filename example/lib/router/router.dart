import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/router/router.gr.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/users/users_screen.dart';

// export 'package:auto_route/auto_route.dart';
// export 'router.gr.txt';

@MaterialAutoRouter()
class Router extends $Router {
  @RoutesList()
  static const routes = <AutoRoute>[
    AutoRoute(page: HomeScreen, initial: true),
    AutoRoute(
      path: '/users',
      page: UsersScreen,
      children: subRoutes,
    ),
  ];

  static const subRoutes = [
    AutoRoute(path: '/details/:user', page: UsersScreen),
  ];
}
