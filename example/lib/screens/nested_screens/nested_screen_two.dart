import 'package:auto_route/auto_route_annotations.dart';
import 'package:flutter/material.dart';

class NestedScreenTwo extends StatelessWidget {
  final String id;

  const NestedScreenTwo({title, @pathParam this.id});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FlatButton(
          child: Text("Users $id"),
          onPressed: () {},
        ),
      ],
    );
  }
}
