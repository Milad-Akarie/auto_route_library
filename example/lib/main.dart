import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'router/route_guards.dart';
import 'router/router.gr.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final _exNavigatorKey = GlobalKey<ExtendedNavigatorState>();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: ExtendedNavigator(
        key: _exNavigatorKey,
        router: Router(),
        initialRoute: "/",
        guards: [AuthGuard()],
      ),
    );
  }
}
