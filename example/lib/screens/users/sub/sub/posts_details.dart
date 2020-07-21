import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class PostDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Posts detailfs"),
      ),
      body: Column(
        children: <Widget>[
          FlatButton(
            child: Text("Pop root"),
            onPressed: () async {
              context.rootNavigator.pop();
            },
          ),
        ],
      ),
    );
  }
}
