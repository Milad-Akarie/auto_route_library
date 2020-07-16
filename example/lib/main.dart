import 'package:example/router/route_guards.dart';
import 'package:example/router/router.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final navigatorKey = GlobalKey<ExtendedNavigatorState>();
  final router = Router();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        builder: ExtendedNavigator(
      router: Router(),
      initialRoute: "/",
      guards: [AuthGuard()],
    )
//
        );
  }
}
