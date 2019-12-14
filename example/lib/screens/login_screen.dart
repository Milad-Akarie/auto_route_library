import 'package:example/screens/nested/nested_router.gr.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final double id;

  const LoginScreen({this.id = 20.0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Navigator(
              key: NestedRouter.navigatorKey,
              onGenerateRoute: NestedRouter.onGenerateRoute,
            ),
          ),
          FlatButton(
            child: Text("NestedScreen Screen"),
            onPressed: () {
              NestedRouter.navigator.pushNamed(NestedRouter.nestedPage);
            },
          ),
        ],
      ),
    );
  }
}
