import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget implements AutoRouteWrapper {
  final String message;

  const SecondScreen({title, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          FlatButton(
            child: Text("NestedScreen Screen"),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  @override
  Widget get wrappedRoute => Container(child: this);
}
