import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final routerConfig = MyRouterConfig(
      // authRouteGuard: AuthRouteGuard()
      );

  @override
  Widget build(BuildContext context) {
    print('Building App');
    return MaterialApp.router(
      routerDelegate: RootRouterDelegate(
        routerConfig,
        // defaultHistory: [
        //   // HomeScreenRoute(),
        //   // TestPageRoute(),
        //   // // LoginScreenRoute(),
        //   // UsersScreenRoute(id: '1', children: [
        //   //   ProfileScreenRoute(),
        //   //   PostsScreenRoute(),
        //   // ])
        // ],
      ),
      routeInformationParser: routerConfig.nativeRouteParser,
      routeInformationProvider: routerConfig.defaultProvider('/users'),
    );
  }
}
