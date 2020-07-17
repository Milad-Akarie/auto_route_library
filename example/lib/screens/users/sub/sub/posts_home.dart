import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../router/router.gr.dart';

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
              context.navigator.push(PostsScreenRoutes.postDetails);
            },
          ),
        ],
      ),
    );
  }
}
