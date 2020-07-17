import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final String redirectTo;
  final Object destinationArgs;

  const LoginScreen({this.redirectTo, this.destinationArgs});
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ExtendedNavigator.of(context).pop(false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false,),
        body: Center(
          child: FlatButton(
            child: Text("Login"),
            onPressed: () async {
              ExtendedNavigator.of(context).pop<bool>(true);
            },
          ),
        ),
      ),
    );
  }
}
