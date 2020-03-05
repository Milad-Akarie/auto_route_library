import 'package:auto_route/auto_route.dart';
import 'package:example/router.gr.dart';
import 'package:flutter/material.dart';

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
            ExtendedNavigator.of(context).pop<bool>(true);
          },
        ),
      ),
    );
  }
}
