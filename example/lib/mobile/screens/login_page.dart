import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final void Function(bool isLoggedIn) onLoginResult;

  const LoginPage({Key key, this.onLoginResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // onWillPop: () {
      //   onLoginResult?.call(false);
      //   return SynchronousFuture(true);
      // },
      child: Scaffold(
        appBar: AppBar(
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
