import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            child: Center(
              child: FlatButton(
                child: Text("Users Screen"),
                onPressed: () async {
                  AutoRouter.root.push("/users");
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
