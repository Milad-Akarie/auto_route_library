import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.dart';
import 'package:example/screens/users/users_screen.dart';
import 'package:flutter/material.dart';

class PostsScreen extends StatelessWidget {
  final int userId;

  const PostsScreen({Key key, this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Users Posts Page"),
      ),
      body: Column(
        children: <Widget>[
          FlatButton(
            child: Text("Go Back"),
            onPressed: () {
//              ExtendedNavigator.root.popUntilRoot();
            },
          ),
        ],
      ),
    );
  }
}
