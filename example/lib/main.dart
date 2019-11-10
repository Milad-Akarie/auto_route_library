import 'package:auto_route/router_annotation.dart';
import 'package:flutter/material.dart';

import 'main.router.dart';

void main() => runApp(MyApp());

@RouterApp()
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: Router.onGenerateRoute,
      initialRoute: Router.homePageRoute,
    );
  }
}
