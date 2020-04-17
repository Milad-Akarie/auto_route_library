import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen(String name) {
    print('constructing  Home screen $name');
  }

  @override
  Widget build(BuildContext context) {
    print('building home scree');
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            child: Center(
              child: FlatButton(
                child: Text("Second Screen"),
                onPressed: () async {
                  ExtendedNavigator.ofRouter<Router>().pushNamed(
                      Routes.secondScreen,
                      arguments: SecondScreenArguments(message: 'title'),
                      onReject: (guard) {
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: Text('You need to be looged in'),
                            ));
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
