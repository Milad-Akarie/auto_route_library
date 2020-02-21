import 'package:example/router.dart';
import 'package:example/router.gr.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
  Router.navigator.addGuards([
    AuthGuard(),
  ]);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: Router.onGenerateRoute,
      initialRoute: Router.homeScreen,
      navigatorKey: Router.navigator.key,
    );
  }
}
