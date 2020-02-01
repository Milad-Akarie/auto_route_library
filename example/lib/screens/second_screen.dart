import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'nested/nested_router.gr.dart';

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
          Expanded(
            child: Navigator(
              key: NestedRouter.navigator.key,
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

  @override
  Widget get wrappedRoute => Container(child: this);
}
