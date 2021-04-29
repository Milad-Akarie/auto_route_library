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
  bool _showlogin = false;
  bool _showApp = false;
  @override
  void initState() {
    super.initState();
    _authService.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    var authenticated = _authService.isAuthenticated;
    _showlogin = !authenticated;
    _showApp = authenticated;
    print('Building');
    return MaterialApp.router(
      theme: ThemeData.dark(),
      routerDelegate: AutoRouterDelegate.declarative(
        _rootRouter,
        onInitialRoutes: (tree) async {
          await Future.delayed(Duration(milliseconds: 300));
          setState(() {
            _showlogin = !authenticated;
            _showApp = authenticated;
          });
          return null;
        },
        routes: (context) {
          return [
            if (_showApp) AppRoute(),
            if (_showlogin)
              LoginRoute(onLoginResult: (success) {
                _authService.isAuthenticated = success;
              }),
          ];
        },
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
