import 'package:auto_route/auto_route.dart';
import 'package:example/router/route_guards.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// import 'router/router.gr.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final routerConfig = MyRouterConfig(authRouteGuard: AuthRouteGuard());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: RootRouterDelegate(routerConfig),
      routeInformationParser: routerConfig.nativeRouteParser,
    );
  }
}
