import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/router/route_guards.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/second_screen.dart';
import 'package:example/screens/unknown_route.dart';

// export 'package:auto_route/auto_route.dart';
// export 'router.gr.txt';

@MaterialAutoRouter(
  generateNavigationHelperExtension: true,
  generateArgsHolderForSingleParameterRoutes: true,
  routesClassName: 'Routes',
//  routePrefix: '/prefix/',
)
class $Router {
  @initial
  HomeScreen homeScreen;

  @CustomRoute(fullscreenDialog: true)
  @GuardedBy([AuthGuard])
  SecondScreen secondScreen;

  LoginScreen loginScreen;

  @unknownRoute
  UnknownRouteScreen unknownRouteScreen;
}
