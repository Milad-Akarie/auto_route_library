import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/screens/users/sub/profile_screen.dart';
import 'package:example/screens/users/sub/user_details.dart';
import 'package:example/screens/users/users_router.gr.dart';

@MaterialAutoRouter()
class UsersRouter extends $UsersRouter {
  @RoutesList()
  static const userRoutes = <AutoRoute>[
    MaterialRoute<String>(page: UserDetails, initial: true),
    MaterialRoute(page: ProfileScreen),
  ];
}
