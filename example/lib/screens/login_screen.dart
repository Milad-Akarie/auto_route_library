import 'package:auto_route/auto_route.dart';
import 'package:example/router.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  final double id;

  LoginScreen({this.id = 20.0}) {
    print('constructing  login screen');
  }

  @override
  Widget build(BuildContext context) {
    print('building login screen');
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
              final prefs = await SharedPreferences.getInstance();
              prefs.setString('token', 'token value');
              // ExtendedNavigator.of(context)
              //     .pushReplacementNamed(Routes.homeScreen);
              // ExtendedNavigator.of(context).pop(true);
              ExtendedNavigator.of(context)
                  .pushReplacementNamed(Routes.homeScreen);
            },
          ),
        ),
      ),
    );
  }
}
