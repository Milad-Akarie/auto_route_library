import 'package:auto_route/auto_route.dart';
import 'package:example/router/route_guards.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: ExtendedNavigator<Router>(
        initialRoute: Routes.homeScreen,
        router: Router(),
        initialRouteArgs: HomeScreenArguments(name: 'name'),
        guards: [AuthGuard()],
      ),
    );
  }
}
