import 'package:auto_route/router.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

@AutoRouteApp(["ProductDetails,login"])
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: Router.onGenerateRoute,
      initialRoute: Router.HomeScreen,
    );
  }
}
