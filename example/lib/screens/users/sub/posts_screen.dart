import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class PostsScreen extends StatelessWidget {
  final int userId;

  const PostsScreen({Key key, this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Users Posts Page"),
//          actions: [FlatButton(onPressed: Text("post details"),onLongPress: {},)],
        ),
        body: ExtendedNavigator());
  }
}
