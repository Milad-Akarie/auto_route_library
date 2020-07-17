import 'package:flutter/material.dart';

import '../../../../router/router.dart';

class PostDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Posts details"),
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
