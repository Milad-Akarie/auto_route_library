import 'package:auto_route/auto_route_annotation.dart';
import 'package:example/generic_type_two.dart';
import 'package:example/router.dart';
import 'package:flutter/material.dart';

import '../generic_type.dart';

@AutoRoute()
class SecondScreen extends StatelessWidget {
  final String title;
  final String message;
  final GenericType<List<GenericTypeTwo<String>>> generic;

  const SecondScreen({@required this.title, this.message, this.generic});

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
              NestedRouter.navigator.pushNamed(NestedRouter.initialRoute);
            },
          ),
        ],
      ),
    );
  }
}
