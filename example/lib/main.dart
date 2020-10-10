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
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      // builder uses the native nav key to keep
      // the state of ExtendedNavigator so it won't reload
      // when using Flutter tools-> select widget mode
      builder: ExtendedNavigator.builder<AppRouter>(
          router: AppRouter(),
          initialRoute: '/',
          guards: [AuthGuard()],
          builder: (ctx, extendedNav) => Theme(
                data: ThemeData.dark(),
                child: extendedNav,
              )),
    );
  }
}
