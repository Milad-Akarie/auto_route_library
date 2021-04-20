import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/db.dart';
import 'router/web_router.gr.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appRouter = WebAppRouter();

  PageRouteInfo? _usersRoute;
  PageRouteInfo? _notFoundRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      routerDelegate: AutoRouterDelegate(
        _appRouter,
        // onInitialRoutes: (tree) {
        //   _notFoundRoute = null;
        //   _usersRoute = null;
        //
        //   if (tree.topRoute?.routeName == UserRoute.name) {
        //     _usersRoute = tree.topRoute;
        //   } else if (tree.topRoute?.routeName == NotFoundRoute.name) {
        //     _notFoundRoute = tree.topRoute;
        //   }
        // },
        // routes: (context) => [
        //       HomeRoute(navigate: () {
        //         setState(() {
        //           _usersRoute = UserRoute(id: 4);
        //         });
        //       }),
        //       if (_usersRoute != null) _usersRoute!,
        //       if (_notFoundRoute != null) _notFoundRoute!,
        //     ],
        // onPopRoute: (route) {
        //   if (route.routeName == UserRoute.name) {
        //     _usersRoute = null;
        //   }
        // }
      ),
      routeInformationParser: _appRouter.defaultRouteParser(),
      builder: (_, router) {
        return BooksDBProvider(
          child: router!,
        );
      },
    );
  }
}
