import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/material.dart';

class PostsHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Posts home'),
      ),
      body: Column(
        children: <Widget>[
          FlatButton(
            child: Text('Posts Details'),
            onPressed: () {
              context.router.push(PostDetailsRoute());
            },
          ),
        ],
      ),
    );
  }
}
