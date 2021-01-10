import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final void Function(bool isLoggedIn) onLoginResult;
  final bool showBackButton;
  const LoginPage({Key key, this.onLoginResult, this.showBackButton = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // onWillPop: () {
      //   onLoginResult?.call(false);
      //   return SynchronousFuture(true);
      // },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: showBackButton,
          title: Text('Login to continue'),
        ),
        body: Center(
          child: RaisedButton(
            child: Text('Login'),
            onPressed: () {
              onLoginResult?.call(true);
            },
          ),
        ),
      ),
    );
  }
}
