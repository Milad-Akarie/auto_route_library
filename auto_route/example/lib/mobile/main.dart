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
  final _rootRouter = RootRouter(
      // authGuard: AuthGuard(),
      );

  // final _authService = AuthService();

  // @override
  // void initState() {
  //   super.initState();
  //   _authService.addListener(() => setState(() {}));
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.dark(),
      routerDelegate: AutoRouterDelegate(
        _rootRouter,
      ),
      routeInformationProvider: AutoRouteInformationProvider(),
      routeInformationParser: _rootRouter.defaultRouteParser(
          // includePrefixMatches: true,
          ),
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

class MyObserver extends AutoRouterObserver {
  @override
  void didPush(Route route, Route? previousRoute) {}
}
