import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/db.dart';
import 'router/router.gr.dart';
import 'package:path/path.dart' as path;

class MyObserver extends AutoRouterObserver {
  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) {
    print('Did init tab route: ${route.name}  previous: ${previousRoute?.name}');
  }

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) {
    print('Did change tab route: ${route.name}  previous: ${previousRoute.name}');
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    print('Did push route ${route.settings.name}');
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appRouter = AppRouter(authGuard: AuthGuard());

  var showHome = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      routerDelegate: AutoRouterDelegate(
        _appRouter,
        // navigatorObservers: () => [MyObserver()],
        // initialDeepLink: '/home/books/2'
        // initialRoutes: [
        //   HomeRoute(),
        // ],
        // routes: (context) {
        //   return [
        //     if (context.watch<AuthService>().isAuthenticated)
        //       HomeRoute()
        //     else
        //       LoginRoute(
        //         onLoginResult: (loggedIn) {
        //           setState(() {
        //             showHome = loggedIn;
        //           });
        //         },
        //       ),
        //   ];
        // },
        // onPopRoute: (route) {
        //   if (route.routeName == HomeRoute.name) {
        //     showHome = false;
        //   }
        // },
      ),
      routeInformationParser: _appRouter.defaultRouteParser(),
      builder: (_, router) {
        return ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
          child: BooksDBProvider(
            child: router!,
          ),
        );
      },
    );
  }
}
