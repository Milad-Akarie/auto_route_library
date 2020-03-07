import 'package:example/router.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('building home scree');
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: Center(
          child: FlatButton(
            child: Text("Second Screen"),
            onPressed: () async {
              ExtendedNavigator.root.pushNamed(
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
