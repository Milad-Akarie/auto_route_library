import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/db.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _rootRouter = RootRouter();
  PageRouteInfo _initialLocation = AppRouter(
    children: [
      HomeRoute(children: [ProfileTab()])
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      routerDelegate: AutoRouterDelegate.declarative(
        _rootRouter,
        onInitialRoutes: (tree) {
          // if (tree.topRoute != null) {
          //   _initialLocation = tree.topRoute!;
          // }
        },
        routes: (context) {
          var authenticated = context.watch<AuthService>().isAuthenticated;
          return [
            if (authenticated) _initialLocation else LoginRoute(),
          ];
        },
      ),
      routeInformationParser: _rootRouter.defaultRouteParser(),
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
