import 'package:auto_route/auto_route_annotation.dart';
import 'package:flutter/material.dart';

import '../router.dart';

@InitialRoute()
class HomeScreen extends StatelessWidget {
  final int id;

  const HomeScreen(this.id);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: Center(
          child: FlatButton(
            child: Text("Second Screen"),
            onPressed: () {
              Router.navigator.pushNamed(Router.customRouteName, arguments: "String");
            },
          ),
        ),
      ),
    );
  }
}
