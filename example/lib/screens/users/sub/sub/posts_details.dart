import 'package:example/router/router.dart';
import 'package:flutter/material.dart';

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
              ExtendedNavigator.root.pop();
              // or without Context
              // ExtendedNavigator.byName("usersRouter").pushNamed(UsersScreenRoutes.postsScreen);
            },
          ),
        ],
      ),
    );
  }
}
