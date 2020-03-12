import 'package:auto_route/auto_route.dart';
import 'package:example/router.dart';
import 'package:flutter/material.dart';

import '../router.gr.dart';

class LoginScreen extends StatelessWidget {
  final double id;

  const LoginScreen({this.id = 20.0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: FlatButton(
          child: Text("Login"),
          onPressed: () {
            isUserLoggedIn = true;
            ExtendedNavigator.of(context)
                .pushReplacementNamed(Routes.homeScreen);
          },
        ),
      ),
    );
  }
}
