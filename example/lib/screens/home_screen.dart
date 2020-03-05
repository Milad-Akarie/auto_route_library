import 'package:auto_route/auto_route.dart';
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
              ExtendedNavigator.of(context).pushNamed(
                Routes.secondScreen,
                arguments: SecondScreenArguments(title: 'title'),
              );
            },
          ),
        ),
      ),
    );
  }
}
