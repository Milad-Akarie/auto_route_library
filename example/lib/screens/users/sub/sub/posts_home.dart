import 'package:flutter/material.dart';

class PostsHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Posts home"),
      ),
      body: Column(
        children: <Widget>[
          FlatButton(
            child: Text("Posts Details"),
            onPressed: () async {
//              AutoRouter.of(context).push(PostsScreenRoutes.postDetails);
            },
          ),
        ],
      ),
    );
  }
}
