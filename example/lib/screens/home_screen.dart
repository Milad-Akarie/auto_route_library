
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../router/router.dart';

class HomeScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            child: Center(
              child: FlatButton(
                child: Text("Users Screen"),
                onPressed: () async {
//                  context.navigator.router.findMatch(settings)
                  context.navigator.push("/users/23/posts?foo=bar");
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
