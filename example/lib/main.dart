import 'package:example/router/route_guards.dart';
import 'package:example/router/router.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("loading app");
    return MaterialApp(
        builder: AutoRouter(
          routeGenerator: Router(),
          initialRoute: "/",
          guards: [AuthGuard()],
        ));
  }
}
