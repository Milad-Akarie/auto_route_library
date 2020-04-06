import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final double id;

  LoginScreen({this.id = 20.0});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ExtendedNavigator.rootNavigator.pop(false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(),
        body: Center(
          child: FlatButton(
            child: Text("Login"),
            onPressed: () async {
              ExtendedNavigator.of(context)
                  .pushReplacementNamed(Routes.homeScreen);
              // ExtendedNavigator.rootNavigator.pop(true);
            },
          ),
        ),
      ),
    );
  }
}
