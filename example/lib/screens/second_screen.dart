import 'package:flutter/material.dart';

import 'nested/nested_router.gr.dart';

class SecondScreen extends StatelessWidget {
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
