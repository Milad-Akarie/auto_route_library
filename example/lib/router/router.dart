import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/generic_a.dart';
import 'package:example/generic_b.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/unknown_route.dart';
import 'package:example/screens/users/sub/profile_screen.dart';
import 'package:example/screens/users/sub/user_details.dart';
import 'package:example/screens/users/users_screen.dart';

export 'package:auto_route/auto_route.dart';

export 'router.gr.dart';

@MaterialAutoRouter(
  routes: <AutoRoute>[
    CustomRoute(page: HomeScreen, initial: true),
    MaterialRoute<GenericA<GenericB<int>>>(
      path: '/users',
      page: UsersScreen,
      children: [
        CustomRoute(path: '/', page: UserDetails),
        MaterialRoute(path: '/profile', page: ProfileScreen),
      ],
    ),
    CustomRoute<bool>(path: "/login", page: LoginScreen, fullscreenDialog: true),
    MaterialRoute(path: "*", page: UnknownRouteScreen)
  ],
)
class $Router {}

class TemplateDef {
  final name;

  const TemplateDef(this.name);

  String call() => name;
}
