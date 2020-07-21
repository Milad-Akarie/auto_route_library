import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'router/route_guards.dart';
import 'router/router.gr.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // builder uses the native nav key to keep
      // the state of ExtendedNavigator so it won't reload
      // when using Flutter tools-> select widget mode
      builder: ExtendedNavigator.builder(
        router: Router(),
        initialRoute: "/",
        guards: [AuthGuard()],
        builder: (_, extendedNav) => Theme(
          data: ThemeData(brightness: Brightness.dark),
          child: extendedNav,
        ),
      ),
    );
  }
}
