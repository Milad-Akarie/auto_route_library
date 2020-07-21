import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class PostsScreen extends StatelessWidget {
  final int userId;

  const PostsScreen({this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Users Posts Page"),
      ),
      body: Hero(
        tag: 'Hero',
        child: Center(
          child: SizedBox(
            height: 100,
            width: 300,
            child: FlatButton(
              textColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              color: Colors.red,
              child: Text("Users Posts"),
              onPressed: () {
                context.rootNavigator.pop();
              },
            ),
          ),
        ),
      ),
    );

//        body: ExtendedNavigator());
  }
}
