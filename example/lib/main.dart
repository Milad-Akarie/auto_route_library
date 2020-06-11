import 'package:auto_route/auto_route.dart';
import 'package:example/router/route_guards.dart';
import 'package:example/router/router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: Router(),
      builder: ExtendedNavigator(
//        initialRoute: '/',
        router: Router(),
        guards: [AuthGuard()],
      ),
    );
  }
}
