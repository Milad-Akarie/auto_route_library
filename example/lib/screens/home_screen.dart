import 'package:flutter/material.dart';

import '../router.gr.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: Center(
          child: FlatButton(
            child: Text("Second Screen"),
            onPressed: () async {
              Router.navigator.pushNamed(Router.secondScreenRoute,
                  arguments: SecondScreenArguments(title: 'title'));
            },
          ),
        ),
      ),
    );
  }
}
