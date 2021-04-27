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

  @override
  void initState() {
    super.initState();
    _authService.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      routerDelegate: AutoRouterDelegate.declarative(
        _rootRouter,
        routes: (context) {
          var authenticated = _authService.isAuthenticated;
          return [
            if (authenticated)
              AppRoute()
            else
              LoginRoute(onLoginResult: (success) {
                _authService.isAuthenticated = success;
              }),
          ];
        },
      ),
      routeInformationParser: _rootRouter.defaultRouteParser(),
      builder: (_, router) {
        return BooksDBProvider(
          child: router!,
        );
      },
    );
  }
}
