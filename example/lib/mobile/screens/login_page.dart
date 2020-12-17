import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final void Function(bool loggedIn) onResult;

  LoginPage({Key key, this.onResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login to continue'),
      ),
      body: Center(
        child: RaisedButton(
          child: Text('Login'),
          onPressed: () {
            if (onResult != null) {
              onResult(true);
            }
          },
        ),
      ),
    );
  }
}
