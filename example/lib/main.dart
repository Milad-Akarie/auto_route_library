import 'package:example/router.dart';
import 'package:example/router.gr.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
  Router.instance.registerGuards([AuthGuard()]);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: Router.instance.onGenerateRoute,
      initialRoute: Router.homeScreenRoute,
      navigatorKey: Router.instance.key,
    );
  }
}
