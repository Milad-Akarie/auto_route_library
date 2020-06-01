import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/router/router.gr.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/second_screen.dart';
import 'package:flutter/cupertino.dart';

// export 'package:auto_route/auto_route.dart';
// export 'router.gr.txt';

@MaterialAutoRouter()
class Router extends $Router {
  @RoutesList()
  static const routes = <AutoRoute>[
    AutoRoute(page: HomeScreen, initial: true),
    AutoRoute(
      path: '/second/{id}',
      page: SecondScreen,
//      children: [
//        AutoRoute(path: '/details/{user}', page: SecondNested),
//      ],
    ),
  ];

  @override
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    print(settings);
    return super.onGenerateRoute(settings);
  }
}

//class Route<T> {
//  Route x;
//  final String path;
//  final T screen;
//
//  const Route({this.path, this.screen});
//}

//@RoutesList()
//const routes = <String, dynamic>{
//  '/': HomeScreen,
//  '/second/{id}/product': MaterialRoute(
//    SecondScreen,
//    guards: [AuthGuard],
//    fullscreenDialog: true,
//  ),
//};

//class $Router {
//  @initial
//  HomeScreen homeScreen;
//  Route x;
//
//  @GuardedBy([AuthGuard])
//  @CupertinoRoute(fullscreenDialog: true)
//  SecondScreen secondScreen;

//  LoginScreen loginScreen;

//  @unknownRoute
//  UnknownRouteScreen unknownRouteScreen;
//}
