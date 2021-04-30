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
  final _authService = AuthService();
  PageRouteInfo _appLocation = const AppRoute();

  @override
  void initState() {
    super.initState();
    _authService.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    var authenticated = _authService.isAuthenticated;

    return MaterialApp.router(
      theme: ThemeData.dark(),
      routerDelegate: AutoRouterDelegate.declarative(
        _rootRouter,
        onRoutes: (tree, initial) async {
          _appLocation = tree.topRoute ?? const AppRoute();
          return null;
        },
        routes: (_) => [
          if (authenticated)
            _appLocation
          else
            LoginRoute(onLoginResult: (success) {
              _authService.isAuthenticated = success;
            }),
        ],
      ),
      routeInformationParser: _rootRouter.defaultRouteParser(),
      builder: (_, router) {
        return ChangeNotifierProvider<AuthService>.value(
          value: _authService,
          child: BooksDBProvider(
            child: router!,
          ),
        );
      },
    );
  }
}
