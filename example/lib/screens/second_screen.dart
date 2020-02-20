import 'package:auto_route/auto_route.dart';
import 'package:example/router.gr.dart';
import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget implements AutoRouteWrapper {
  final String title;
  final String message;

  const SecondScreen({@required this.title, this.message});

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
