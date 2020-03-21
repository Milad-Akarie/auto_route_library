import 'package:auto_route/auto_route.dart';
import 'package:example/screens/nested_screens/nested_router.gr.dart';
import 'package:flutter/material.dart';

class NestedScreenTwo extends StatelessWidget {
  final String message;

  const NestedScreenTwo({title, this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FlatButton(
          child: Text("Pop stack"),
          onPressed: () {
            ExtendedNavigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
