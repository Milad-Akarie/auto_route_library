import 'package:auto_route/auto_route.dart';
import 'package:example/router.dart';
import 'package:example/router.gr.dart';
import 'package:example/screens/home_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: ExtendedNavigator(
        // initialRoute: Routes.secondScreen,
        placeHolder: Container(
          color: Colors.red,
        ),
        router: Router(),
        guards: [AuthGuard()],
      ),
    );
  }
}
