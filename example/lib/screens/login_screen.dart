import 'package:auto_route/auto_route.dart';
import 'package:example/router.dart';
import 'package:flutter/material.dart';

import '../router.gr.dart';

class LoginScreen extends StatelessWidget {
  final double id;

  const LoginScreen({this.id = 20.0});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ExtendedNavigator.root.pop(false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(),
        body: Center(
          child: FlatButton(
            child: Text("Login"),
            onPressed: () async {
              // final prefs = await SharedPreferences.getInstance();
              // prefs.setString('token', 'token value');
              // ExtendedNavigator.of(context)
              //     .pushReplacementNamed(Routes.homeScreen);
              ExtendedNavigator.of(context).pop(true);
            },
          ),
        ),
      ),
    );
  }
}
