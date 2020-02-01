import 'package:example/router.gr.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: Router.onGenerateRoute,
      initialRoute: Router.homeScreenRoute,
      navigatorKey: Router.navigator.key,
    );
  }
}
